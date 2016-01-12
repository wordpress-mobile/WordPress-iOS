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
#import "Blog.h"
#import "WPAnalyticsTrackerWPCom.h"

#import "WordPress-Swift.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSString *const NotificationsDeviceToken = @"apnsDeviceToken";


#pragma mark ====================================================================================
#pragma mark NotificationsManager
#pragma mark ====================================================================================

@implementation NotificationsManager

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

@end
