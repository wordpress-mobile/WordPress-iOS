/*
 *    HelpshiftCore.h
 *    SDK Version 5.10.0
 *
 *    Get the documentation at http://www.helpshift.com/docs
 *
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol HsApiProvider <NSObject>
- (void) _installForApiKey:(NSString *)apiKey domainName:(NSString *)domainName appID:(NSString *)appID;
- (void) _installForApiKey:(NSString *)apiKey domainName:(NSString *)domainName appID:(NSString *)appID withOptions:(NSDictionary *)optionsDictionary;

- (BOOL) _loginWithIdentifier:(NSString *)identifier withName:(NSString *)name andEmail:(NSString *)email;
- (BOOL) _logout;
- (void) _setName:(NSString *)name andEmail:(NSString *)email;
- (void) _registerDeviceToken:(NSData *)deviceToken;
- (BOOL) _handleRemoteNotification:(NSDictionary *)notification withController:(UIViewController *)viewController;
- (BOOL) _handleRemoteNotification:(NSDictionary *)notification isAppLaunch:(BOOL)isAppLaunch withController:(UIViewController *)viewController;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (BOOL) _handleLocalNotification:(UILocalNotification *)notification withController:(UIViewController *)viewController;
- (BOOL) _handleInteractiveRemoteNotification:(NSDictionary *)notification forAction:(NSString *)actionIdentifier completionHandler:(void (^)())completionHandler;
- (BOOL) _handleInteractiveLocalNotification:(UILocalNotification *)notification forAction:(NSString *)actionIdentifier completionHandler:(void (^)())completionHandler;
#pragma clang diagnostic pop
- (BOOL) _handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;
- (BOOL) _setSDKLanguage:(NSString *)langCode;

@end

typedef enum HsAddFAQsToDeviceSearch
{
    HsAddFaqsToDeviceSearchOnInstall = 0,
    HsAddFaqsToDeviceSearchAfterViewingFAQs,
    HsAddFaqsToDeviceSearchNever
}HsAddFAQsToDeviceSearch;

typedef enum HsOperator
{
    HsOperatorAnd = 0,
    HsOperatorOr,
    HsOperatorNot
} HsOperator;

typedef enum HsEnableContactUs
{
    HsEnableContactUsAlways = 0,
    HsEnableContactUsAfterViewingFAQs,
    HsEnableContactUsAfterMarkingAnswerUnhelpful,
    HsEnableContactUsNever
} HsEnableContactUs;

@interface HelpshiftFAQFilter : NSObject
/*
 * For more information about these configs, please visit the developer docs (https://developers.helpshift.com/ios/support-tools/#faq-filtering )
 */
@property (readonly, nonatomic) HsOperator filterOperator;
@property (readonly, nonatomic) NSArray *tags;

/*
 * Initialize HelpshiftFAQFilter object with custom values.
 */
- (id) initWithFilterOperator:(HsOperator)filterOperator andTags:(NSArray *)tags;

/*
 * Use the initWithFilterOperatorAndTags api to initialize.
 */
- (id) init NS_UNAVAILABLE;
@end

@interface HelpshiftSupportMetaData : NSObject
/*
 * For more information about these configs, please visit the developer docs (https://developers.helpshift.com/ios/tracking/#metadata )
 */
@property (readonly, nonatomic) NSDictionary *metaData;
@property (readonly, nonatomic) NSArray *issueTags;

/*
 * Initialize SupportMetaData object with metaData.
 */
- (id) initWithMetaData:(NSDictionary *)metaData;

/*
 * Initialize SupportMetaData object with metaData and issue tags.
 */
- (id) initWithMetaData:(NSDictionary *)metaData andTags:(NSArray *)tags;

/*
 * Use the initWithMetaData or initWithMetaDataAndTags api to initialize.
 */
- (id) init NS_UNAVAILABLE;
@end

@interface HelpshiftInstallConfig : NSObject
- (id) init NS_UNAVAILABLE;
@end

@interface HelpshiftInstallConfigBuilder : NSObject
@property (nonatomic, assign) BOOL enableDefaultFallbackLanguage;
@property (nonatomic, assign) BOOL disableEntryExitAnimations;
@property (nonatomic, assign) BOOL enableInboxPolling;
@property (nonatomic, assign) BOOL enableInAppNotifications;
@property (nonatomic, assign) BOOL enableLogging;
@property (nonatomic, assign) HsAddFAQsToDeviceSearch addFaqsToDeviceSearch;
@property (strong, nonatomic) NSDictionary *extraConfig;

- (HelpshiftInstallConfig *) build;
@end

@interface HelpshiftAPIConfig : NSObject
- (id) init NS_UNAVAILABLE;
@end

@interface HelpshiftAPIConfigBuilder : NSObject
@property (nonatomic, assign) BOOL gotoConversationAfterContactUs;
@property (nonatomic, assign) BOOL presentFullScreenOniPad;
@property (nonatomic, assign) BOOL requireEmail;
@property (nonatomic, assign) BOOL hideNameAndEmail;
@property (nonatomic, assign) BOOL enableFullPrivacy;
@property (nonatomic, assign) BOOL showSearchOnNewConversation;
@property (nonatomic, assign) BOOL showConversationResolutionQuestion;
@property (nonatomic, assign) BOOL enableChat;
@property (nonatomic, assign) HsEnableContactUs enableContactUs;
@property (strong, nonatomic) NSString *conversationPrefillText;
@property (strong, nonatomic) NSArray *customContactUsFlows;
@property (strong, nonatomic) HelpshiftFAQFilter *withTagsMatching;
@property (strong, nonatomic) HelpshiftSupportMetaData *customMetaData;
@property (strong, nonatomic) NSDictionary *extraConfig;

- (HelpshiftAPIConfig *) build;
@end

@interface HelpshiftCore : NSObject
/**
 *  Initialize the HelpshiftCore class with an instance of the Helpshift service which you want to use.
 *
 *  @param apiProvider An implementation of the HsApiProvider protocol. Current implementors of this service are the HelpshiftCampaigns, HelpshiftSupport and HelpshiftAll classes.
 */
+ (void) initializeWithProvider:(id <HsApiProvider>)apiProvider;

/** Initialize helpshift support
 *
 * When initializing Helpshift you must pass these three tokens. You initialize Helpshift by adding the following lines in the implementation file for your app delegate, ideally at the top of application:didFinishLaunchingWithOptions. This method can throw the InstallException asynchronously if the install keys are not in the correct format.
 *
 *  @param apiKey This is your developer API Key
 *  @param domainName This is your domain name without any http:// or forward slashes
 *  @param appID This is the unique ID assigned to your app
 *
 *  Available in SDK version 5.0.0 or later
 */
+ (void) installForApiKey:(NSString *)apiKey domainName:(NSString *)domainName appID:(NSString *)appID;

/** Initialize helpshift support
 *
 * When initializing Helpshift you must pass these three tokens. You initialize Helpshift by adding the following lines in the implementation file for your app delegate, ideally at the top of application:didFinishLaunchingWithOptions. This method can throw the InstallException asynchronously if the install keys are not in the correct format.
 *
 * @param apiKey This is your developer API Key
 * @param domainName This is your domain name without any http:// or forward slashes
 * @param appID This is the unique ID assigned to your app
 * @param optionsDictionary This is the dictionary which contains additional configuration options for the HelpshiftSDK.
 *
 * Available in SDK version 5.0.0 or later
 */

+ (void) installForApiKey:(NSString *)apiKey domainName:(NSString *)domainName appID:(NSString *)appID withOptions:(NSDictionary *)optionsDictionary;

/** Initialize helpshift support
 *
 * When initializing Helpshift you must pass these three tokens. You initialize Helpshift by adding the following lines in the implementation file for your app delegate, ideally at the top of application:didFinishLaunchingWithOptions
 *
 * @param apiKey This is your developer API Key
 * @param domainName This is your domain name without any http:// or forward slashes
 * @param appID This is the unique ID assigned to your app
 * @param withConfig This is the install config object which contains additional configuration options for the HelpshiftSDK.
 *
 * @available Available in SDK version 5.7.0 or later
 */

+ (void) installForApiKey:(NSString *)apiKey domainName:(NSString *)domainName appID:(NSString *)appID withConfig:(HelpshiftInstallConfig *)configObject;
/** Login a user with a given identifier
 *
 * The identifier uniquely identifies the user. Name and email are optional.
 *
 * @param name The name of the user
 * @param email The email of the user
 *
 * Available in SDK version 5.0.0 or later
 *
 */
+ (void) loginWithIdentifier:(NSString *)identifier withName:(NSString *)name andEmail:(NSString *)email;

/** Logout the currently logged in user
 *
 * After logout, Helpshift falls back to the default device login.
 *
 * Available in SDK version 5.0.0 or later
 *
 */
+ (void) logout;

/** Set the name and email of the application user.
 *
 *
 *   @param name The name of the user.
 *   @param email The email address of the user.
 *
 *   Available in SDK version 5.0.0 or later
 */

+ (void) setName:(NSString *)name andEmail:(NSString *)email;

/** Register the deviceToken to enable push notifications
 *
 *
 * To enable push notifications in the Helpshift iOS SDK, set the Push Notifications’ deviceToken using this method inside your application:didRegisterForRemoteNotificationsWithDeviceToken application delegate.
 *
 *  @param deviceToken The deviceToken received from the push notification servers.
 *
 *  Available in SDK version 5.0.0 or later
 *
 */
+ (void) registerDeviceToken:(NSData *)deviceToken;

/**
 *  Pass along a notification to the Helpshift SDK to handle
 *
 *  @param notification   Notification dictionary
 *  @param viewController The viewController on which you want the Helpshift SDK stack to be shown
 *
 *  @return BOOL value indicating whether Helpshift handled this push notification.
 */
+ (BOOL) handleRemoteNotification:(NSDictionary *)notification withController:(UIViewController *)viewController;

/**
 *  Pass along a notification to the Helpshift SDK to handle
 *
 *  @param notification   Notification dictionary
 *  @param isAppLaunch    A boolean indicating whether the app was lanuched from a killed state. This parameter should ideally only be true in case when called from app's didFinishLaunchingWithOptions delegate.
 *  @param viewController The viewController on which you want the Helpshift SDK stack to be shown
 *
 *  @return BOOL value indicating whether Helpshift handled this push notification.
 */
+ (BOOL) handleRemoteNotification:(NSDictionary *)notification isAppLaunch:(BOOL)isAppLaunch withController:(UIViewController *)viewController;

/**
 *  Pass along a local notification to the Helpshift SDK
 *
 *  @param notification   notification object received in the Application's delegate method
 *  @param viewController The viewController on which you want the Helpshift SDK stack to be shown
 *
 *  @return BOOL value indicating whether Helpshift handled this push notification.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (BOOL) handleLocalNotification:(UILocalNotification *)notification withController:(UIViewController *)viewController;
#pragma clang diagnostic pop

/**
 *  Pass along an interactive notification to the Helpshift SDK
 *
 *  @param notification      notification object received in the Application's delegate
 *  @param actionIdentifier  identifier of the action which was executed in the notification
 *  @param completionHandler completion handler
 *
 *  @return BOOL value indicating whether Helpshift handled this push notification.
 */
+ (BOOL) handleInteractiveRemoteNotification:(NSDictionary *)notification forAction:(NSString *)actionIdentifier completionHandler:(void (^)())completionHandler;

/**
 *  Pass along an interactive local notification to the Helpshift SDK
 *
 *  @param notification      notification object received in the Application's delegate
 *  @param actionIdentifier  identifier of the action which was executed in the notification
 *  @param completionHandler completion handler
 *
 *  @return BOOL value indicating whether Helpshift handled this push notification.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (BOOL) handleInteractiveLocalNotification:(UILocalNotification *)notification forAction:(NSString *)actionIdentifier completionHandler:(void (^)())completionHandler;
#pragma clang diagnostic pop

/**
 *  If an app is woken up in the background in response to a background session being completed, call this API from the
 *  Application's delegate method. Helpshift SDK extensively uses background NSURLSessions for data syncing.
 *
 *  @param identifier        identifier of the background session
 *  @param completionHandler completion handler
 *
 *  @return BOOL value indicating whether Helpshift handled this push notification.
 */
+ (BOOL) handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;

/** Change the SDK language. By default, the device's prefered language is used.
 *  If a Helpshift session is already active at the time of invocation, this call will fail and will return false.
 *
 * @param languageCode the string representing the language code. For example, use 'fr' for French.
 *
 * @return BOOL indicating wether the specified language was applied. In case the language code is incorrect or
 * the corresponding localization file was not found, bool value of false is returned and the default language is used.
 *
 * Available in SDK version 5.5.0 or later
 */
+ (BOOL) setSDKLanguage:(NSString *)languageCode;

@end
