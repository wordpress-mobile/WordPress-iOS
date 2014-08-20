#import "NotificationsManager.h"
#import "Note.h"
#import "NotificationsViewController.h"

#import "WordPressAppDelegate.h"
#import "UIDevice+WordPressIdentifier.h"

#import "WordPressComApi.h"
#import <WPXMLRPCClient.h>

#import "ContextManager.h"
#import "AccountService.h"
#import "WPAccount.h"

#import <Helpshift/Helpshift.h>
#import <Simperium/Simperium.h>
#import <Mixpanel/Mixpanel.h>



static NSString *const NotificationsDeviceIdKey                 = @"notification_device_id";
static NSString *const NotificationsPreferencesKey              = @"notification_preferences";
NSString *const NotificationsDeviceToken                        = @"apnsDeviceToken";

// These correspond to the 'category' data WP.com will send with a push notification
NSString *const NotificationCategoryCommentApproved             = @"APPROVED";
NSString *const NotificationCategoryCommentApprovedWithLike     = @"APPROVED_LIKE";
NSString *const NotificationCategoryCommentUnapproved           = @"UNAPPROVED";

NSString *const NotificationActionCommentReply                  = @"COMMENT_REPLY";
NSString *const NotificationActionCommentLike                   = @"COMMENT_LIKE";
NSString *const NotificationActionCommentApprove                = @"COMMENT_MODERATE_APPROVE";

@implementation NotificationsManager

+ (void)registerForPushNotifications
{
#if TARGET_IPHONE_SIMULATOR
    return;
#endif
    // Register for push notifications
    [[UIApplication sharedApplication] registerForRemoteNotifications];

    // Add the categories to UIUserNotificationSettings
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:[self buildNotificationCategories]];

    // Finally, register the notification settings
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}

#pragma mark - Device token registration

+ (void)registerDeviceToken:(NSData *)deviceToken
{
    // We want to register Helpshift regardless so that way if a user isn't logged in
    // they can still get push notifications that we replied to their support ticket.
    [[Helpshift sharedInstance] registerDeviceToken:deviceToken];

    [[Mixpanel sharedInstance].people addPushDeviceToken:deviceToken];

    // Don't bother registering for WordPress anything if the user isn't logged in
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    if (![accountService defaultWordPressComAccount]) {
        return;
    }

    NSString *newToken  = [deviceToken.description stringByReplacingOccurrencesOfString: @"<" withString: @""];
    newToken            = [newToken stringByReplacingOccurrencesOfString: @">" withString: @""];
    newToken            = [newToken stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    DDLogInfo(@"Device token received in didRegisterForRemoteNotificationsWithDeviceToken: %@", newToken);

    // Store the token
    NSUserDefaults *userDefaults    = [NSUserDefaults standardUserDefaults];
    NSString *previousToken         = [userDefaults objectForKey:NotificationsDeviceToken];
    
    if (![previousToken isEqualToString:newToken]) {
        DDLogInfo(@"Device Token has changed! OLD Value %@, NEW value %@", previousToken, newToken);
        [userDefaults setObject:newToken forKey:NotificationsDeviceToken];
        [userDefaults synchronize];
    }

    [self syncPushNotificationInfo];
}

+ (void)registrationDidFail:(NSError *)error
{
    DDLogError(@"Failed to register for push notifications: %@", error);
    [self unregisterDeviceToken];
}

+ (void)unregisterDeviceToken
{
    NSString *deviceId              = [[NSUserDefaults standardUserDefaults] stringForKey:NotificationsDeviceIdKey];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount       = [accountService defaultWordPressComAccount];
    
    [[defaultAccount restApi] unregisterForPushNotificationsWithDeviceId:deviceId
                                                                 success:^{
                                                                     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                                     [defaults removeObjectForKey:NotificationsDeviceToken];
                                                                     [defaults removeObjectForKey:NotificationsDeviceIdKey];
                                                                     [defaults removeObjectForKey:NotificationsPreferencesKey];
                                                                     [defaults synchronize];
                                                                 } failure:^(NSError *error){
                                                                     DDLogError(@"Couldn't unregister push token: %@", [error localizedDescription]);
                                                                 }];
}

+ (BOOL)deviceRegisteredForPushNotifications
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:NotificationsDeviceToken] != nil;
}

#pragma mark - Notification handling

+ (void)handleNotification:(NSDictionary *)userInfo forState:(UIApplicationState)state completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DDLogVerbose(@"Received push notification:\nPayload: %@\nCurrent Application state: %d", userInfo, state);

    // Try to pull the badge number from the notification object
    // Badge count does not normally update when the app is active, and this forces KVO to be fired
    NSNumber *badgeCount = [[userInfo dictionaryForKey:@"aps"] numberForKey:@"badge"];
    if (badgeCount) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = badgeCount.intValue;
    }

    // Check if it is the badge reset PN
    if ([[userInfo stringForKey:@"type"] isEqualToString:@"badge-reset"]) {
        return;
    }

    if ([[userInfo stringForKey:@"origin"] isEqualToString:@"helpshift"]) {
        UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        [[Helpshift sharedInstance] handleRemoteNotification:userInfo withController:rootViewController];
        return;
    }

    if (state == UIApplicationStateInactive) {
        NSString *notificationID            = [[userInfo numberForKey:@"note_id"] stringValue];
        WordPressAppDelegate *appDelegate   = [WordPressAppDelegate sharedWordPressApplicationDelegate];
        
        [appDelegate showTabForIndex:kNotificationsTabIndex];
        [appDelegate.notificationsViewController showDetailsForNoteWithID:notificationID animated:NO];
    } else if (state == UIApplicationStateBackground) {
        if (completionHandler) {
            Simperium *simperium = [[WordPressAppDelegate sharedWordPressApplicationDelegate] simperium];
            [simperium backgroundFetchWithCompletion:^(UIBackgroundFetchResult result) {
                if (result == UIBackgroundFetchResultNewData) {
                    DDLogVerbose(@"Background Fetch Completed with New Data!");
                } else {
                    DDLogVerbose(@"Background Fetch Completed with No Data..");
                        }
                        completionHandler(result);
            }];
        }
    }
}

+ (void)handleNotificationForApplicationLaunch:(NSDictionary *)launchOptions
{
    NSDictionary *remoteNotif = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif) {
        DDLogVerbose(@"Launched with a remote notification as parameter:  %@", remoteNotif);
        [[WordPressAppDelegate sharedWordPressApplicationDelegate] showTabForIndex:kNotificationsTabIndex];
    }
}

+ (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)remoteNotification {
    // Ensure we have a WP.com account
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    if (![[defaultAccount restApi] hasCredentials]) {
        return;
    }
    
    // Comment like
    if ([identifier isEqualToString:NotificationActionCommentLike]) {
        // Get the site and comment id and like the comment via the REST API
        NSInteger blogId = [remoteNotification[@"blog_id"] integerValue];
        NSInteger commentId = [remoteNotification[@"comment_id"] integerValue];
        
        if (blogId && commentId) {
            [[defaultAccount restApi] likeComment: blogId
                                     forCommentID:commentId
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              DDLogInfo(@"Liked comment from push notification");
                                          }
                                          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              DDLogInfo(@"Couldn't like comment from push notification");
                                          }
             ];
            
        }
    } else if ([identifier isEqualToString:NotificationActionCommentApprove]) {
        // Moderate comment
        NSString *newStatus = @"approved";
        NSInteger blogId = [remoteNotification[@"blog_id"] integerValue];
        NSInteger commentId = [remoteNotification[@"comment_id"] integerValue];

        if (blogId && commentId) {
            [[defaultAccount restApi] moderateComment:blogId forCommentID:commentId withStatus:newStatus
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              DDLogInfo(@"Successfully moderated comment from push notification");
                                          }
                                          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              DDLogInfo(@"Couldn't moderate comment from push notification");
                                          }
             ];
        }
    } else if ([identifier isEqualToString:NotificationActionCommentReply]) {
        NSString *notificationID            = [[remoteNotification numberForKey:@"note_id"] stringValue];
        WordPressAppDelegate *appDelegate   = [WordPressAppDelegate sharedWordPressApplicationDelegate];

        [appDelegate showTabForIndex:kNotificationsTabIndex];
        [appDelegate.notificationsViewController showDetailsForNoteWithID:notificationID animated:NO];
    }
}


#pragma mark - WordPress.com XML RPC API

+ (NSDictionary *)notificationSettingsDictionary
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount       = [accountService defaultWordPressComAccount];

    if (![[defaultAccount restApi] hasCredentials]) {
        return nil;
    }

    NSDictionary *notificationPreferences = [[NSUserDefaults standardUserDefaults] objectForKey:NotificationsPreferencesKey];
    if (!notificationPreferences) {
        return nil;
    }

    NSMutableArray *notificationPrefArray = [[notificationPreferences allKeys] mutableCopy];
    if ([notificationPrefArray indexOfObject:@"muted_blogs"] != NSNotFound) {
        [notificationPrefArray removeObjectAtIndex:[notificationPrefArray indexOfObject:@"muted_blogs"]];
    }

    // Build the dictionary to send in the API call
    NSMutableDictionary *updatedSettings = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [notificationPrefArray count]; i++) {
        NSDictionary *updatedSetting = [notificationPreferences objectForKey:[notificationPrefArray objectAtIndex:i]];
        [updatedSettings setValue:[updatedSetting objectForKey:@"value"] forKey:[notificationPrefArray objectAtIndex:i]];
    }

    //Check and send 'mute_until' value
    NSMutableDictionary *muteDictionary = [notificationPreferences objectForKey:@"mute_until"];
    if (muteDictionary != nil  && [muteDictionary objectForKey:@"value"] != nil) {
        [updatedSettings setValue:[muteDictionary objectForKey:@"value"] forKey:@"mute_until"];
    } else {
        [updatedSettings setValue:@"0" forKey:@"mute_until"];
    }

    NSArray *blogsArray = [[notificationPreferences objectForKey:@"muted_blogs"] objectForKey:@"value"];
    NSMutableArray *mutedBlogsArray = [[NSMutableArray alloc] init];
    for (int i=0; i < [blogsArray count]; i++) {
        NSDictionary *userBlog = [blogsArray objectAtIndex:i];
        if ([[userBlog objectForKey:@"value"] intValue] == 1) {
            [mutedBlogsArray addObject:userBlog];
        }
    }

    if ([mutedBlogsArray count] > 0) {
        [updatedSettings setValue:mutedBlogsArray forKey:@"muted_blogs"];
    }

    if ([updatedSettings count] == 0) {
        return nil;
    }

    return updatedSettings;
}

+ (void)saveNotificationSettings
{
    NSDictionary *settings          = [NotificationsManager notificationSettingsDictionary];
    NSString *deviceId              = [[NSUserDefaults standardUserDefaults] stringForKey:NotificationsDeviceIdKey];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount       = [accountService defaultWordPressComAccount];

    [[defaultAccount restApi] saveNotificationSettings:settings
                                              deviceId:deviceId
                                               success:^{
                                                   DDLogInfo(@"Notification settings successfully sent to WP.com\n Settings: %@", settings);
                                               } failure:^(NSError *error){
                                                   DDLogError(@"Failed to update notification settings on WP.com %@", error.localizedDescription);
                                               }];
}

+ (void)fetchNotificationSettingsWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSString *deviceId              = [[NSUserDefaults standardUserDefaults] stringForKey:NotificationsDeviceIdKey];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount       = [accountService defaultWordPressComAccount];
    
    [[defaultAccount restApi] fetchNotificationSettingsWithDeviceId:deviceId
                                                            success:^(NSDictionary *settings) {
                                                                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                                [defaults setObject:settings forKey:NotificationsPreferencesKey];
                                                                [defaults synchronize];
                                                                
                                                                DDLogInfo(@"Received notification settings %@", settings);
                                                                if (success) {
                                                                    success();
                                                                }
                                                            } failure:^(NSError *error) {
                                                                DDLogError(@"Failed to fetch notification settings %@ with device ID %@", error, deviceId);
                                                                if (failure) {
                                                                    failure(error);
                                                                }
                                                            }];
}

+ (void)syncPushNotificationInfo
{
    NSString *token                 = [[NSUserDefaults standardUserDefaults] objectForKey:NotificationsDeviceToken];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount       = [accountService defaultWordPressComAccount];

    [[defaultAccount restApi] syncPushNotificationInfoWithDeviceToken:token
                                         success:^(NSString *deviceId, NSDictionary *settings) {
                                             DDLogVerbose(@"Synced push notification token and received device ID %@ with settings:\n %@", deviceId, settings);

                                             NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                             [defaults setObject:deviceId forKey:NotificationsDeviceIdKey];
                                             [defaults setObject:settings forKey:NotificationsPreferencesKey];
                                             [defaults synchronize];
                                         } failure:^(NSError *error) {
                                             DDLogError(@"Failed to receive supported notification list: %@", error);
                                         }
     ];
}


#pragma mark - Enhanced Notifications

+ (NSSet *)buildNotificationCategories {
    // Build the notification actions
    UIMutableUserNotificationAction *commentReplyAction = [[UIMutableUserNotificationAction alloc] init];
    commentReplyAction.identifier = NotificationActionCommentReply;
    commentReplyAction.title = NSLocalizedString(@"Reply", @"Reply to a comment (verb)");
    commentReplyAction.activationMode = UIUserNotificationActivationModeForeground;
    commentReplyAction.destructive = NO;
    commentReplyAction.authenticationRequired = YES;

    UIMutableUserNotificationAction *commentLikeAction = [[UIMutableUserNotificationAction alloc] init];
    commentLikeAction.identifier = NotificationActionCommentLike;
    commentLikeAction.title = NSLocalizedString(@"Like", @"Like (verb)");
    commentLikeAction.activationMode = UIUserNotificationActivationModeBackground;
    commentLikeAction.destructive = NO;
    commentLikeAction.authenticationRequired = NO;

    UIMutableUserNotificationAction *commentApproveAction = [[UIMutableUserNotificationAction alloc] init];
    commentApproveAction.identifier = NotificationActionCommentApprove;
    commentApproveAction.title = NSLocalizedString(@"Approve", @"Approve comment (verb)");
    commentApproveAction.activationMode = UIUserNotificationActivationModeBackground;
    commentApproveAction.destructive = NO;
    commentApproveAction.authenticationRequired = YES;

    // Add actions to categories
    UIMutableUserNotificationCategory *commentApprovedCategory = [[UIMutableUserNotificationCategory alloc] init];
    commentApprovedCategory.identifier = NotificationCategoryCommentApproved;
    [commentApprovedCategory setActions:@[commentReplyAction] forContext:UIUserNotificationActionContextDefault];

    UIMutableUserNotificationCategory *commentApprovedWithLikeCategory = [[UIMutableUserNotificationCategory alloc] init];
    commentApprovedWithLikeCategory.identifier = NotificationCategoryCommentApprovedWithLike;
    [commentApprovedWithLikeCategory setActions:@[commentLikeAction, commentReplyAction] forContext:UIUserNotificationActionContextDefault];

    UIMutableUserNotificationCategory *commentUnapprovedCategory = [[UIMutableUserNotificationCategory alloc] init];
    commentUnapprovedCategory.identifier = NotificationCategoryCommentUnapproved;
    [commentUnapprovedCategory setActions:@[commentApproveAction] forContext:UIUserNotificationActionContextDefault];

    return [NSSet setWithObjects:commentApprovedCategory, commentApprovedWithLikeCategory, commentUnapprovedCategory, nil];
}

@end
