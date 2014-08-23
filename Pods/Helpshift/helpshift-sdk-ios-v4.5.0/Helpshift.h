/*
 *    Helpshift.h
 *    SDK version 4.5.0
 *
 *    Get the documentation at http://www.helpshift.com/docs
 *
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * This document describes the API exposed by the Helpshift SDK (4.x) which the developers can use to integrate Helpshift support into their iOS applications. If you want documentation regarding how to use the various features provided by the Helpshift SDK, please visit the [developer docs](http://developers.helpshift.com/)
 */

typedef enum HSAlertToRateAppAction
{
    HS_RATE_ALERT_CLOSE = 0,
    HS_RATE_ALERT_FEEDBACK,
    HS_RATE_ALERT_SUCCESS,
    HS_RATE_ALERT_FAIL
} HSAlertToRateAppAction;

typedef NSDictionary * (^metadataBlock)(void);
typedef void (^AppRatingAlertViewCompletionBlock)(HSAlertToRateAppAction);

// A Reserved key (HSCustomMetadataKey) constant to be used in options dictionary of showFAQs, showConversation, showFAQSection, showSingleFAQ to
// provide a dictionary for custom data to be attached along with new conversations.
//
// If you want to attach custom data along with new conversation, use this constant key and a dictionary value containing the meta data key-value pairs
// and pass it in withOptions param before calling any of the 4 support APIs.
//
// Available in SDK version 4.2.0 or later
//
// Example usages:
//  NSDictionary *metaDataWithTags = @{@"usertype": @"paid", @"level":@"7", @"score":@"12345", HSTagsKey:@[@"feedback",@"paid user",@"v4.1"]};
//  [[Helpshift sharedInstance] showFAQs:self withOptions:@{@"gotoConversationAfterContactUs":@"YES", HSCustomMetadataKey: metaDataWithTags}];
//
//  NSDictionary *metaData = @{@"usertype": @"paid", @"level":@"7", @"score":@"12345"]};
//  [[Helpshift sharedInstance] showConversation:self withOptions:@{HSCustomMetadataKey: metaData}];
//
extern NSString *const HSCustomMetadataKey;


// A Reserved key (HSTagsKey) constant to be used with metadataBlock (of type NSDictionary) to pass NSArray (of type only NSStrings)
// which get interpreted at server and added as Tags for the issue being reported.
// If an object in NSArray is not of type NSString then the object will be removed from Tags and will not be added for the issue.
//
// Available in SDK version 3.2.0 or later
// Example usage 1:
//    [Helpshift metadataWithBlock:^(void){
//        return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"feedback", @"paid user",nil], HSTagsKey, nil];
//    }];
// Example usage 2 (Available in SDK version 4.2.0 or later):
//    NSDictionary *metaData = @{@"usertype": @"paid", @"level":@"7", @"score":@"12345", HSTagsKey:@[@"feedback",@"paid user",@"v4.1"]};
//    [[Helpshift sharedInstance] showConversation:self withOptions:@{HSCustomMetadataKey: metaData}];
//
extern NSString *const HSTagsKey;


@protocol HelpshiftDelegate;
@interface Helpshift : NSObject <UIAlertViewDelegate>
{
    id <HelpshiftDelegate> delegate;
}

@property (nonatomic,retain) id<HelpshiftDelegate> delegate;

/** Initialize helpshift support
 *
 * When initializing Helpshift you must pass these three tokens. You initialize Helpshift by adding the following lines in the implementation file for your app delegate, ideally at the top of application:didFinishLaunchingWithOptions. If you use this api to initialize helpshift support, in-app notifications will be enabled by default.
 * In-app notifications are banner like notifications shown by the Helpshift SDK to alert the user of any updates to an ongoing conversation.
 * If you want to disable the in-app notifications please refer to the installForAppID:domainName:apiKey:withOptions: api
 *
 *  @param apiKey This is your developer API Key
 *  @param domainName This is your domain name without any http:// or forward slashes
 *  @param appID This is the unique ID assigned to your app
 *
 *  @available Available in SDK version 4.0.0 or later
 */
+ (void) installForApiKey:(NSString *)apiKey domainName:(NSString *)domainName appID:(NSString *)appID;

/** Initialize helpshift support
 *
 * When initializing Helpshift you must pass these three tokens. You initialize Helpshift by adding the following lines in the implementation file for your app delegate, ideally at the top of application:didFinishLaunchingWithOptions
 *
 * @param apiKey This is your developer API Key
 * @param domainName This is your domain name without any http:// or forward slashes
 * @param appID This is the unique ID assigned to your app
 * @param withOptions This is the dictionary which contains additional configuration options for the HelpshiftSDK. Currently we support the "enableInAppNotification" as the only available option. Possible values are <"YES"/"NO">. If you set the flag to "YES", the helpshift SDK will show notifications similar to the banner notifications supported by Apple Push notifications. These notifications will alert the user of any updates to ongoing conversations. If you set the flag to "NO", the in-app notifications will be disabled.
 *
 * @available Available in SDK version 4.0.0 or later
 */

+ (void) installForApiKey:(NSString *)apiKey domainName:(NSString *)domainName appID:(NSString *)appID withOptions:(NSDictionary *)optionsDictionary;

/** Returns an instance of Helpshift
 *
 * When calling any Helpshift instance method you must use sharedInstance. For example to call showSupport: you must call it like [[Helpshift sharedInstance] showSupport:self];
 *
 * @available Available in SDK version 1.0.0 or later
 */
+ (Helpshift *) sharedInstance;

/** To pause and restart the display of inapp notification
 *
 * When this method is called with boolean value YES, inapp notifications are paused and not displayed.
 * To restart displaying inapp notifications pass the boolean value NO.
 *
 * @param pauseInApp the boolean value to pause/restart inapp nofitications
 *
 * @available Available in SDK version 4.3.0 or later
 */
+ (void) pauseDisplayOfInAppNotification:(BOOL)pauseInApp;

/** Show the helpshift conversation screen (with Optional Arguments)
 *
 * To show the Helpshift conversation screen with optional arguments you will need to pass the name of the viewcontroller on which the conversation screen will show up and an options dictionary. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param viewController viewController on which the helpshift report issue screen will show up.
 * @param optionsDictionary the dictionary which will contain the arguments passed to the Helpshift conversation session (that will start with this method call).
 *
 * Please check the docs for available options.
 *
 * @available Available in SDK version 4.0.0 or later
 */
- (void) showConversation:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/** Show the support screen with only the faqs (with Optional Arguments)
 *
 * To show the Helpshift screen with only the faq sections with search with optional arguments, you can use this api. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param viewController viewController on which the helpshift faqs screen will show up.
 * @param optionsDictionary the dictionary which will contain the arguments passed to the Helpshift faqs screen session (that will start with this method call).
 *
 * Please check the docs for available options.
 *
 * @available Available in SDK version 2.0.0 or later
 */

- (void) showFAQs:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/** Show the helpshift screen with faqs from a particular section
 *
 * To show the Helpshift screen for showing a particular faq section you need to pass the publish-id of the faq section and the name of the viewcontroller on which the faq section screen will show up. For example from inside a viewcontroller you can call the Helpshift faq section screen by passing the argument “self” for the viewController parameter. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param faqSectionPublishID the publish id associated with the faq section which is shown in the FAQ page on the admin side (__yourcompanyname__.helpshift.com/admin/faq/).
 * @param viewController viewController on which the helpshift faq section screen will show up.
 * @param optionsDictionary the dictionary which will contain the arguments passed to the Helpshift session (that will start with this method call).
 *
 * @available Available in SDK version 2.0.0 or later
 */

- (void) showFAQSection:(NSString *)faqSectionPublishID withController:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/** Show the helpshift screen with a single faq
 *
 * To show the Helpshift screen for showing a single faq you need to pass the publish-id of the faq and the name of the viewcontroller on which the faq screen will show up. For example from inside a viewcontroller you can call the Helpshift faq section screen by passing the argument “self” for the viewController parameter. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param faqPublishID the publish id associated with the faq which is shown when you expand a single FAQ (__yourcompanyname__.helpshift.com/admin/faq/)
 * @param viewController viewController on which the helpshift faq section screen will show up.
 * @param optionsDictionary the dictionary which will contain the arguments passed to the Helpshift session (that will start with this method call).
 *
 * @available Available in SDK version 4.0.0 or later
 */

- (void) showSingleFAQ:(NSString *)faqPublishID withController:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/** Show alert for app rating
 *
 * To manually show an alert for app rating, you need automated reviews disabled in admin.
 * Also, if there is an ongoing conversation, the review alert will not show up.
 *
 * @available Available in SDK version 4.4.0 or later
 */
+ (void) showAlertToRateAppWithURL:(NSString *)url withCompletionBlock:(AppRatingAlertViewCompletionBlock)completionBlock;

/** Set an user identifier for your users.
 *
 * This is part of additional user configuration. The user identifier will be passed through to the admin dashboard as "User ID" under customer info.
 *  @param userIdentifier A string to identify your users.
 *
 *  @available Available in SDK version 1.0.0 or later
 */

+ (void) setUserIdentifier:(NSString *)userIdentifier;

/** Set the name and email of the application user.
 *
 * This is part of additional user configuration. If this is provided through the api, user will not be prompted to re-enter this information again.
 * Pass nil values for both name and email to clear out old existing values.
 *
 *   @param name The name of the user.
 *   @param email The email address of the user.
 *
 *   @available Available in SDK version 4.0.0 or later
 */

+ (void) setName:(NSString *)name andEmail:(NSString *)email;

/** Add extra debug information regarding user-actions.
 *
 * You can add additional debugging statements to your code, and see exactly what the user was doing right before they reported the issue.
 *
 *  @param breadCrumbString The string containing any relevant debugging information.
 *
 *  @available Available in SDK version 1.0.0 or later
 */

+ (void) leaveBreadCrumb:(NSString *)breadCrumbString;

/** Provide a block which returns a dictionary for custom meta data to be attached along with new conversations
 *
 * If you want to attach custom data along with any new conversation, use this api to provide a block which accepts zero arguments and returns an NSDictionary containing the meta data key-value pairs. Everytime an issue is reported, the SDK will call this block and attach the returned meta data dictionary along with the reported issue. Ideally this metaDataBlock should be provided before the user can file an issue.
 *
 *  @param metadataBlock a block variable which accepts zero arguments and returns an NSDictionary.
 *
 *  @available Available in SDK version 4.0.0 or later
 */

+ (void) setMetadataBlock:(metadataBlock)metadataBlock;

/** Get the notification count for replies to new conversations.
 *
 *
 * If you want to show your user notifications for replies on any ongoing conversation, you can get the notification count asynchronously by implementing the HelpshiftDelegate in your respective .h and .m files.
 * Use the following method to set the delegate, where self is the object implementing the delegate.
 * [[Helpshift sharedInstance] setDelegate:self];
 * Now you can call the method
 * [[Helpshift sharedInstance] getNotificationCountFromRemote:YES];
 * This will return a notification count in the
 * - (void) didReceiveNotificationCount:(NSInteger)count
 * count delegate method.
 * If you want to retrieve the current notification count synchronously, you can call the same method with the parameter set to false, i.e
 * NSInteger count = [[Helpshift sharedInstance] getNotificationCountFromRemote:NO]
 *
 * @param isRemote Whether the notification count is to be returned asynchronously via delegate mechanism or synchronously as a return val for this api
 *
 * @available Available in SDK version 4.0.0 or later
 */

- (NSInteger) getNotificationCountFromRemote:(BOOL)isRemote;

/** Register the deviceToken to enable push notifications
 *
 *
 * To enable push notifications in the Helpshift iOS SDK, set the Push Notifications’ deviceToken using this method inside your application:didRegisterForRemoteNotificationsWithDeviceToken application delegate.
 *
 *  @param deviceToken The deviceToken received from the push notification servers.
 *
 * Example usage
 *  - (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:
 *              (NSData *)deviceToken
 *  {
 *      [[Helpshift sharedInstance] registerDeviceToken:deviceToken];
 *  }
 *
 *  @available Available in SDK version 1.4.0 or later
 *
 */
- (void) registerDeviceToken:(NSData *)deviceToken;

/** Forward the push notification for the Helpshift lib to handle
 *
 *
 * To show support on Notification opened, call handleRemoteNotification in your application:didReceiveRemoteNotification application delegate.
 * If the value of the “origin” field is “helpshift” call the handleRemoteNotification api
 *
 *  @param notification The dictionary containing the notification information
 *  @param viewController ViewController on which the helpshift support screen will show up.
 *
 * Example usage
 *  - (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
 *  {
 *      if ([[userInfo objectForKey:@"origin"] isEqualToString:@"helpshift"]) {
 *          [[Helpshift sharedInstance] handleRemoteNotification:userInfo withController:self.viewController];
 *      }
 *  }
 *
 *  @available Available in SDK version 4.0.0 or later
 *
 */
- (void) handleRemoteNotification:(NSDictionary *)notification withController:(UIViewController *)viewController;

/** Forward the local notification for the Helpshift lib to handle
 *
 *
 * To show support on Notification opened, call handleLocalNotification in your application:didReceiveLocalNotification application delegate.
 * If the value of the “origin” field is “helpshift” call the handleLocalNotification api
 *
 * @param notification The UILocalNotification object containing the notification information
 * @param viewController ViewController on which the helpshift support screen will show up.
 *
 * Example usage
 *  - (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
 *  {
 *      if ([[notification.userInfo objectForKey:@"origin"] isEqualToString:@"helpshift"])
 *      [[Helpshift sharedInstance] handleLocalNotification:notification withController:self.viewController];
 *  }
 *
 * @available Available in SDK version 2.4.0 or later
 *
 */

- (void) handleLocalNotification:(UILocalNotification *)notification withController:(UIViewController *)viewController;

/** Clears Breadcrumbs list.
 *
 * Breadcrumbs list stores upto 100 latest actions. You'll receive those in every Issue.
 * If for some reason you want to clear previous messages, you can use this method.
 *
 * @available Available in SDK version 2.3.0 or later
 *
 */
- (void) clearBreadCrumbs;




// Deprecated API calls

/**
 * @warning Deprecated API call. Use installForApiKey:domainName:appID: instead.
 */
+ (void) installForAppID:(NSString *)appID domainName:(NSString *)domainName apiKey:(NSString *)apiKey
    __attribute__((deprecated("Use installForApiKey:domainName:appID: instead")));

/**
 * @warning Deprecated API call. Use installForApiKey:domainName:appID:withOptions: instead.
 */
+ (void) installForAppID:(NSString *)appID domainName:(NSString *)domainName apiKey:(NSString *)apiKey withOptions:(NSDictionary *)optionsDictionary
    __attribute__((deprecated("Use installForApiKey:domainName:appID:withOptions: instead")));

/**
 * @warning Deprecated API call. Use showFAQs:withOptions: instead.
 */
- (void) showSupport:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary
    __attribute__((deprecated("Use showFAQs:withOptions: instead")));

/**
 * @warning Deprecated API call. Use showFAQs:withOptions: instead.
 */
- (void) showSupport:(UIViewController *)viewController
    __attribute__((deprecated("Use showFAQs:withOptions: instead")));

/**
 * @warning Deprecated API call. Use showFAQs:withOptions: instead.
 */
- (void) showFAQs:(UIViewController *)viewController
    __attribute__((deprecated("Use showFAQs:withOptions: instead")));

/**
 * @warning Deprecated API call. Use showConversation:withOptions: instead.
 */
- (void) reportIssue:(UIViewController *)viewController
    __attribute__((deprecated("Use showConversation:withOptions: instead")));

/**
 * @warning Deprecated API call. Use showConversation:withOptions: instead.
 */
- (void) reportIssue:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary
    __attribute__((deprecated("Use showConversation:withOptions: instead")));

/**
 * @warning Deprecated API call. Use showFAQSection:withController:withOptions: instead.
 */
- (void) showFAQSection:(NSString *)faqSectionPublishID withController:(UIViewController *)viewController
    __attribute__((deprecated("Use showFAQSection:withController:withOptions: instead")));

/**
 * @warning Deprecated API call. Use showSingleFAQ:withController:withOptions: instead.
 */
- (void) showFAQ:(NSString *)faqPublishID withController:(UIViewController *)viewController
    __attribute__((deprecated("Use showSingleFAQ:withController:withOptions: instead")));

/**
 * @warning Deprecated API call. Use showConversation:withOptions: instead.
 */
- (void) showInbox:(UIViewController *)viewController
    __attribute__((deprecated("Use showConversation:withOptions: instead")));

/**
 * @warning Deprecated API call. Use getNotificationCountFromRemote: instead.
 */
- (NSInteger) notificationCountAsync:(BOOL)isAsync
    __attribute__((deprecated("Use getNotificationCountFromRemote: instead")));

/**
 * @warning Deprecated API call. Use handleRemoteNotification:withController: instead.
 */
- (void) handleNotification:(NSDictionary *)notification withController:(UIViewController *)viewController
    __attribute__((deprecated("Use handleRemoteNotification:withController: instead")));

/**
 * @warning Deprecated API call. Use setName:andEmail: instead.
 */
+ (void) setUsername:(NSString *)name
    __attribute__((deprecated("Use setName:andEmail: instead")));

/**
 * @warning Deprecated API call. Use setName:andEmail: instead.
 */
+ (void) setUseremail:(NSString *)email
    __attribute__((deprecated("Use setName:andEmail: instead")));

@end

@protocol HelpshiftDelegate <NSObject>

/** Delegate method call that should be implemented if you are calling getNotificationCountFromRemote:YES
 * @param count Returns the number of unread messages for the ongoing conversation
 *
 * @available Available in SDK version 4.0.0 or later
 */

- (void) didReceiveNotificationCount:(NSInteger)count;

/** Optional delegate method that is called when the Helpshift session ends.
 *
 *
 * Helpshift session is any Helpshift support screen opened via showSupport: or other API calls.
 * Whenever the user closes that support screen and returns back to the app this method is invoked.
 *
 *  @available Available in SDK version 1.4.3 or later
 */
@optional
- (void) helpshiftSessionHasEnded;

/** Optional delegate method that is called when a Helpshift inapp notification arrives and is shown
 *  @param count Returns the number of messages that has arrived via inapp notification.
 *
 * @available Available in SDK version 4.3.0 or later
 */
- (void) didReceiveInAppNotificationWithMessageCount:(NSInteger)count;
@end
