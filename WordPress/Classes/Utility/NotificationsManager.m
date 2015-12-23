#import "NotificationsManager.h"
#import "NotificationsViewController.h"
#import "WPTabBarController.h"

#import "WordPressAppDelegate.h"

#import "WordPressComApi.h"
#import <WordPressApi/WPXMLRPCClient.h>

#import "ContextManager.h"
#import "AccountService.h"
#import "WPAccount.h"
#import "CommentService.h"
#import "BlogService.h"

#import <Helpshift/Helpshift.h>
#import <Simperium/Simperium.h>
#import <Mixpanel/Mixpanel.h>
#import "Blog.h"
#import "WPAnalyticsTrackerWPCom.h"

#import "WordPress-Swift.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

NSString *const NotificationsManagerDidRegisterDeviceToken          = @"NotificationsManagerDidRegisterDeviceToken";
NSString *const NotificationsManagerDidUnregisterDeviceToken        = @"NotificationsManagerDidUnregisterDeviceToken";

static NSString *const NotificationsDeviceIdKey                     = @"notification_device_id";
static NSString *const NotificationsLegacyPreferencesKey            = @"notification_preferences";
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
#if TARGET_IPHONE_SIMULATOR || ALPHA_BUILD
    return;
#endif
    // iOS 8 or higher notifications registration
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
    
    // Notify Listeners
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationsManagerDidRegisterDeviceToken object:newToken];

    [self nukeLegacyPreferences];
    [self registerDeviceTokenWithTokenString:newToken];
}

+ (void)registrationDidFail:(NSError *)error
{
    DDLogError(@"Failed to register for push notifications: %@", error);
    [self unregisterDeviceToken];
}

+ (void)unregisterDeviceToken
{
    NSManagedObjectContext *context     = [[ContextManager sharedInstance] mainContext];
    NotificationsService *noteService   = [[NotificationsService alloc] initWithManagedObjectContext:context];
    NSString *deviceId                  = [self registeredPushNotificationsDeviceId];
    
    [noteService unregisterDeviceForPushNotifications:deviceId success:^{
        DDLogInfo(@"Successfully unregistered Device ID %@ for Push Notifications!", deviceId);
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:NotificationsDeviceToken];
        [defaults removeObjectForKey:NotificationsDeviceIdKey];
        [defaults synchronize];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:NotificationsManagerDidUnregisterDeviceToken object:nil];
    }
    failure:^(NSError *error){
        DDLogError(@"Unable to unregister push for Device ID %@: %@", deviceId, [error localizedDescription]);
    }];
}

+ (BOOL)pushNotificationsEnabledInDeviceSettings
{
    // TODO: I must insist. Let's refactor this entire class please, in another issue!. JLP. Jul.15.2015
    UIApplication *application = [UIApplication sharedApplication];
    return application.currentUserNotificationSettings.types != UIUserNotificationTypeNone;
}

+ (NSString *)registeredPushNotificationsToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:NotificationsDeviceToken];
}

+ (NSString *)registeredPushNotificationsDeviceId
{
    // TODO: Refactor this entire class please!. JLP. Jun.24.2015
    return [[NSUserDefaults standardUserDefaults] objectForKey:NotificationsDeviceIdKey];
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
    
    //Bump Analytics here
    NSMutableDictionary *mutablePushProperties = [NSMutableDictionary new];
    if ([userInfo numberForKey:@"note_id"]) {
         [mutablePushProperties setObject:[[userInfo numberForKey:@"note_id"] stringValue]
                                   forKey:@"push_notification_note_id"];
    }
    if ([userInfo stringForKey:@"type"]) {
        [mutablePushProperties setObject:[userInfo stringForKey:@"type"]
                                  forKey:@"push_notification_type"];
    }
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:NotificationsDeviceToken];
    if (token) {
        // Token should be always available here
        [mutablePushProperties setObject:token forKey:@"push_notification_token"];
    }
    
    if (state == UIApplicationStateBackground) {
        // The notification is delivered when the app isn’t running in the foreground.
        [WPAnalytics track:WPAnalyticsStatPushNotificationReceived withProperties:mutablePushProperties];
    } else if (state == UIApplicationStateInactive) {
        // The user taps the notification item in the notifications center
        [WPAnalytics track:WPAnalyticsStatPushNotificationAlertPressed withProperties:mutablePushProperties];
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

+ (void)nukeLegacyPreferences
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:NotificationsLegacyPreferencesKey];
    [userDefaults synchronize];
}

+ (void)registerDeviceTokenWithTokenString:(NSString *)token
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NotificationsService *noteService = [[NotificationsService alloc] initWithManagedObjectContext:context];

    [noteService registerDeviceForPushNotifications:token success:^(NSString *deviceId) {
        DDLogVerbose(@"Successfully registered Device ID %@ for Push Notifications", deviceId);

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:deviceId forKey:NotificationsDeviceIdKey];
        [defaults synchronize];
    }
    failure:^(NSError *error) {
        DDLogError(@"Unable to register Device for Push Notifications: %@", error);
    }];
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
