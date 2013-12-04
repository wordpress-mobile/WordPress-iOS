/*
 * NotificationsManager.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "NotificationsManager.h"
#import "Note.h"
#import "WordPressAppDelegate.h"
#import "WPAccount.h"
#import "WordPressComApi.h"
#import "UIDevice+WordPressIdentifier.h"
#import <WPXMLRPCClient.h>
#import "ContextManager.h"

@implementation NotificationsManager

+ (void)registerForPushNotifications {
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if (appDelegate.isWPcomAuthenticated) {
        [[UIApplication sharedApplication]
         registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                             UIRemoteNotificationTypeSound |
                                             UIRemoteNotificationTypeAlert)];
    }
}


#pragma mark - Device token registration

+ (void)registerDeviceToken:(NSData *)deviceToken {
    NSString *myToken = [[[[deviceToken description]
                           stringByReplacingOccurrencesOfString: @"<" withString: @""]
                          stringByReplacingOccurrencesOfString: @">" withString: @""]
                         stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    DDLogInfo(@"Device token received in didRegisterForRemoteNotificationsWithDeviceToken: %@", myToken);
    
    // Store the token
    NSString *previousToken = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if (![previousToken isEqualToString:myToken]) {
        DDLogInfo(@"Device Token has changed! OLD Value %@, NEW value %@", previousToken, myToken);
        [[NSUserDefaults standardUserDefaults] setObject:myToken forKey:kApnsDeviceTokenPrefKey];
        [[WordPressComApi sharedApi] syncPushNotificationInfo];
    }
}

+ (void)registrationDidFail:(NSError *)error {
    DDLogError(@"Failed to register for push notifications: %@", error);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey];
}

+ (void)unregisterDeviceToken {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if (nil == token) {
        return;
    }
    
    if (![[WordPressComApi sharedApi] hasCredentials]) {
        return;
    }
    
    NSString *authURL = kNotificationAuthURL;
    WPAccount *account = [WPAccount defaultWordPressComAccount];
	if (account) {
        NSArray *parameters = @[account.username,
                                account.password,
                                token,
                                [[UIDevice currentDevice] wordpressIdentifier],
                                @"apple",
                                @NO, // Sandbox parameter - deprecated
                                WordPressComApiPushAppId
                                ];
        
        WPXMLRPCClient *api = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
        [api setAuthorizationHeaderWithToken:[[WordPressComApi sharedApi] authToken]];
        [api callMethod:@"wpcom.mobile_push_unregister_token"
             parameters:parameters
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    DDLogInfo(@"Unregistered token %@", token);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    DDLogError(@"Couldn't unregister token: %@", [error localizedDescription]);
                }];
    }
}


#pragma mark - Notification handling

+ (void)handleNotification:(NSDictionary*)userInfo forState:(UIApplicationState)state completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    DDLogInfo(@"Received push notification:\nPayload: %@\nCurrent Application state: %d", userInfo, state);
    
    switch (state) {
        case UIApplicationStateActive:
            [[WordPressComApi sharedApi] checkForNewUnseenNotifications];
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
            break;
            
        case UIApplicationStateInactive:
            [WPMobileStats recordAppOpenedForEvent:StatsEventAppOpenedDueToPushNotification];
            [[WordPressAppDelegate sharedWordPressApplicationDelegate] showNotificationsTab];
            break;
            
        case UIApplicationStateBackground:
            [WPMobileStats recordAppOpenedForEvent:StatsEventAppOpenedDueToPushNotification];
            [[WordPressAppDelegate sharedWordPressApplicationDelegate] showNotificationsTab];
            
            if (completionHandler) {
                [Note getNewNotificationswithContext:[[ContextManager sharedInstance] mainContext] success:^(BOOL hasNewNotes) {
                    DDLogInfo(@"notification fetch completion handler completed with new notes: %@", hasNewNotes ? @"YES" : @"NO");
                    if (hasNewNotes) {
                        completionHandler(UIBackgroundFetchResultNewData);
                    } else {
                        completionHandler(UIBackgroundFetchResultNoData);
                    }
                } failure:^(NSError *error) {
                    DDLogError(@"notification fetch completion handler failed with error: %@", error);
                    completionHandler(UIBackgroundFetchResultFailed);
                }];
            }
            break;
        default:
            break;
    }
}

+ (void)handleNotificationForApplicationLaunch:(NSDictionary *)launchOptions {
    NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif) {
        [WPMobileStats recordAppOpenedForEvent:StatsEventAppOpenedDueToPushNotification];
        
        DDLogInfo(@"Launched with a remote notification as parameter:  %@", remoteNotif);
        [[WordPressAppDelegate sharedWordPressApplicationDelegate] showNotificationsTab];
    }
}

@end
