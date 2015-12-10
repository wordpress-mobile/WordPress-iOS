#import <Foundation/Foundation.h>



@interface NotificationsManager : NSObject

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

/**
 Handle an action taken from a remote notification
 
 @param identifier the identifier of the action
 @param remoteNotification the notification object
 */
+ (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)remoteNotification;

@end
