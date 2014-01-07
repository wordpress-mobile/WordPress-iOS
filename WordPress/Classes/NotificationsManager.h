/*
 * NotificationsManager.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

/**
 The persisted device token
 */
extern NSString *const NotificationsDeviceToken;

extern NSString *const NotificationsDeviceToken;

@interface NotificationsManager : NSObject

///--------------------------------
/// @name Device Token registration
///--------------------------------

/**
 Register for push notifications with iOS
 */
+ (void)registerForPushNotifications;

/**
 Register to receive notifications from WordPress.com
 
 @param deviceToken received from applicationDidRegisterForRemoteNotifications:
 */
+ (void)registerDeviceToken:(NSData *)deviceToken;

/**
 Perform cleanup when the registration for iOS notifications failed
 
 @param error detailing the reason for failure
 */
+ (void)registrationDidFail:(NSError *)error;

/**
 Unregister the device from WordPress.com notifications
 */
+ (void)unregisterDeviceToken;

/**
 Returns whether the device is currently registered for remote notifications
 
 @return YES if the device is registered for WordPress.com notifications
 @return NO if not
 */
+ (BOOL)deviceRegisteredForPushNotifications;

///----------------------------
/// @name Notification Handling
///----------------------------

/**
 Handle the notification received, and call the completion handler for background work
 
 @param UIApplicationState at the time of receiving the notification
 @param completionHandler to call in order to complete the task.
        Pass the block the result of the fetch.
 */
+ (void)handleNotification:(NSDictionary *)userInfo forState:(UIApplicationState)state completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;


/**
 Handle a potential remote notification from application launch
 
 @param launchOptions The launch options dictionary passed
 */
+ (void)handleNotificationForApplicationLaunch:(NSDictionary *)launchOptions;

///--------------------------------------
/// @name WordPress.com Notifications API
///--------------------------------------

/**
 Sends the current settings to WordPress.com
 */
+ (void)saveNotificationSettings;

/**
 Fetch the current WordPress.com settings
 */
+ (void)fetchNotificationSettingsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
