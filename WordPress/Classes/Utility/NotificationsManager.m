#import "NotificationsManager.h"
#import "NotificationsViewController.h"
#import "WPTabBarController.h"

#import "WordPressAppDelegate.h"

#import "WordPressComApi.h"
#import <WPXMLRPCClient.h>

#import "ContextManager.h"
#import "AccountService.h"
#import "WPAccount.h"
#import "CommentService.h"
#import "BlogService.h"

#import <Helpshift/Helpshift.h>
#import <Simperium/Simperium.h>
#import <Mixpanel/Mixpanel.h>
#import "Blog.h"

#import "WordPress-Swift.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

NSString *const NotificationsManagerDidRegisterDeviceToken          = @"NotificationsManagerDidRegisterDeviceToken";
NSString *const NotificationsManagerDidUnregisterDeviceToken        = @"NotificationsManagerDidUnregisterDeviceToken";

static NSString *const NotificationsDeviceIdKey                     = @"notification_device_id";
static NSString *const NotificationsPreferencesKey                  = @"notification_preferences";
static NSString *const NotificationsDeviceToken                     = @"apnsDeviceToken";

// These correspond to the 'category' data WP.com will send with a push notification
static NSString *const NotificationCategoryCommentApprove           = @"approve-comment";
static NSString *const NotificationCategoryCommentLike              = @"like-comment";
static NSString *const NotificationCategoryCommentReply             = @"replyto-comment";
static NSString *const NotificationCategoryCommentReplyWithLike     = @"replyto-like-comment";

static NSString *const NotificationActionCommentReply               = @"COMMENT_REPLY";
static NSString *const NotificationActionCommentLike                = @"COMMENT_LIKE";
static NSString *const NotificationActionCommentApprove             = @"COMMENT_MODERATE_APPROVE";


#pragma mark ====================================================================================
#pragma mark NotificationsManager
#pragma mark ====================================================================================

@implementation NotificationsManager

+ (void)registerForPushNotifications
{
#if TARGET_IPHONE_SIMULATOR
    return;
#endif

    BOOL canRegisterUserNotifications = [[UIApplication sharedApplication] respondsToSelector:@selector(registerForRemoteNotifications)];
    if (!canRegisterUserNotifications) {
        // iOS 7 notifications registration
        UIRemoteNotificationType types = (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert);
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
    } else {
        // iOS 8 or higher notifications registration
        [[UIApplication sharedApplication] registerForRemoteNotifications];

        // Add the categories to UIUserNotificationSettings
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:[self buildNotificationCategories]];

        // Finally, register the notification settings
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
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
    
    // Notify Listeners
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationsManagerDidRegisterDeviceToken object:newToken];

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

    void (^successBlock)(void) = ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:NotificationsDeviceToken];
        [defaults removeObjectForKey:NotificationsDeviceIdKey];
        [defaults removeObjectForKey:NotificationsPreferencesKey];
        [defaults synchronize];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:NotificationsManagerDidUnregisterDeviceToken object:nil];
    };
    
    void (^failureBlock)(NSError *error) = ^(NSError *error){
        DDLogError(@"Couldn't unregister push token: %@", [error localizedDescription]);
    };
    
    [defaultAccount.restApi unregisterForPushNotificationsWithDeviceId:deviceId success:successBlock failure:failureBlock];
}

+ (BOOL)deviceRegisteredForPushNotifications
{
    return [self registeredPushNotificationsToken] != nil;
}

+ (NSString *)registeredPushNotificationsToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:NotificationsDeviceToken];
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
        [WPAnalytics track:WPAnalyticsStatSupportReceivedResponseFromSupport];
        UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        [[Helpshift sharedInstance] handleRemoteNotification:userInfo withController:rootViewController];
        return;
    }
    
    if ([[userInfo stringForKey:@"origin"] isEqualToString:@"mp"]) {
        [self handleMixpanelPushNotification:userInfo];
        return;
    }
    
    // WordPress.com Push Authentication Notification
    // Due to the Background Notifications entitlement, any given Push Notification's userInfo might be received
    // while the app is in BG, and when it's about to become active. In order to prevent UI glitches, let's skip
    // notifications when in BG mode.
    //
    PushAuthenticationManager *authenticationManager = [PushAuthenticationManager new];
    if ([authenticationManager isPushAuthenticationNotification:userInfo] && state != UIApplicationStateBackground) {
        [authenticationManager handlePushAuthenticationNotification:userInfo];
        return;
    }
    
    // Notification-Y Push Notifications
    if (state == UIApplicationStateInactive) {
        NSString *notificationID = [[userInfo numberForKey:@"note_id"] stringValue];
        [[WPTabBarController sharedInstance] showNotificationsTabForNoteWithID:notificationID];
    } else if (state == UIApplicationStateBackground) {
        if (completionHandler) {
            Simperium *simperium = [[WordPressAppDelegate sharedInstance] simperium];
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
        [[WPTabBarController sharedInstance] showNotificationsTab];
    }
}

+ (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)remoteNotification
{
    // Ensure we have a WP.com account
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    if (![[defaultAccount restApi] hasCredentials]) {
        return;
    }
    
    // Comment actions
    if ([identifier isEqualToString:NotificationActionCommentLike] || [identifier isEqualToString:NotificationActionCommentApprove]) {
        // Get the site and comment id
        NSNumber *siteID = remoteNotification[@"blog_id"];
        NSNumber *commentID = remoteNotification[@"comment_id"];
        
        if (siteID && commentID) {
            NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
            CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];

            if ([identifier isEqualToString:NotificationActionCommentLike]) {
                [commentService likeCommentWithID:commentID siteID:siteID
                                          success:^{
                                              DDLogInfo(@"Liked comment from push notification");
                                          }
                                          failure:^(NSError *error) {
                                              DDLogInfo(@"Couldn't like comment from push notification");
                                          }];
            } else {
                [commentService approveCommentWithID:commentID siteID:siteID
                                             success:^{
                                                 DDLogInfo(@"Successfully moderated comment from push notification");
                                             }
                                             failure:^(NSError *error) {
                                                 DDLogInfo(@"Couldn't moderate comment from push notification");
                                             }];
            }
        }
    } else if ([identifier isEqualToString:NotificationActionCommentReply]) {
        // Load notifications detail view
        NSString *notificationID = [[remoteNotification numberForKey:@"note_id"] stringValue];
        [[WPTabBarController sharedInstance] showNotificationsTabForNoteWithID:notificationID];
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
    if (!settings) {
        DDLogError(@"%@ %@ returning early because of blank notifications setting dictionary", self, NSStringFromSelector(_cmd));
        return;
    }
    
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

+ (NSSet *)buildNotificationCategories
{
    // Build the notification actions
    UIMutableUserNotificationAction *commentReplyAction = [[UIMutableUserNotificationAction alloc] init];
    commentReplyAction.identifier = NotificationActionCommentReply;
    commentReplyAction.title = NSLocalizedString(@"Reply", @"Reply to a comment (verb)");
    commentReplyAction.activationMode = UIUserNotificationActivationModeForeground;
    commentReplyAction.destructive = NO;
    commentReplyAction.authenticationRequired = NO;

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
    commentApproveAction.authenticationRequired = NO;

    // Add actions to categories
    UIMutableUserNotificationCategory *commentApproveCategory = [[UIMutableUserNotificationCategory alloc] init];
    commentApproveCategory.identifier = NotificationCategoryCommentApprove;
    [commentApproveCategory setActions:@[commentApproveAction] forContext:UIUserNotificationActionContextDefault];

    UIMutableUserNotificationCategory *commentReplyCategory = [[UIMutableUserNotificationCategory alloc] init];
    commentReplyCategory.identifier = NotificationCategoryCommentReply;
    [commentReplyCategory setActions:@[commentReplyAction] forContext:UIUserNotificationActionContextDefault];

    UIMutableUserNotificationCategory *commentLikeCategory = [[UIMutableUserNotificationCategory alloc] init];
    commentLikeCategory.identifier = NotificationCategoryCommentLike;
    [commentLikeCategory setActions:@[commentLikeAction] forContext:UIUserNotificationActionContextDefault];

    UIMutableUserNotificationCategory *commentReplyWithLikeCategory = [[UIMutableUserNotificationCategory alloc] init];
    commentReplyWithLikeCategory.identifier = NotificationCategoryCommentReplyWithLike;
    [commentReplyWithLikeCategory setActions:@[commentLikeAction, commentReplyAction] forContext:UIUserNotificationActionContextDefault];

    return [NSSet setWithObjects:commentApproveCategory, commentReplyCategory, commentLikeCategory, commentReplyWithLikeCategory, nil];
}

#pragma mark - Mixpanel A/B Tests

+ (void)handleMixpanelPushNotification:(NSDictionary *)userInfo
{
    NSString *targetToOpen = [userInfo stringForKey:@"open"];
    if ([targetToOpen isEqualToString:@"reader"]) {
        [[WPTabBarController sharedInstance] showReaderTab];
    } else if ([targetToOpen isEqualToString:@"notifications"]) {
        [[WPTabBarController sharedInstance] showNotificationsTab];
    } else if ([targetToOpen isEqualToString:@"stats"]) {
        [self openStatsForLastUsedOrFirstWPComBlog];
    }
}

+ (void)openStatsForLastUsedOrFirstWPComBlog
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    Blog *blog = [blogService lastUsedOrFirstBlogThatSupports:BlogFeatureStats];
    if (blog != nil) {
        [[WPTabBarController sharedInstance] switchMySitesTabToStatsViewForBlog:blog];
    }
}

@end
