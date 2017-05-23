/*
 *    HelpshiftSupport.h
 *    SDK Version 5.10.1
 *
 *    Get the documentation at http://www.helpshift.com/docs
 *
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HelpshiftCore.h"

typedef enum HelpshiftSupportAlertToRateAppAction
{
    HelpshiftSupportAlertToRateAppActionClose = 0,
    HelpshiftSupportAlertToRateAppActionFeedback,
    HelpshiftSupportAlertToRateAppActionSuccess,
    HelpshiftSupportAlertToRateAppActionFail
} HelpshiftSupportAlertToRateAppAction;

typedef NSDictionary * (^HelpshiftSupportMetadataBlock)(void);
typedef HelpshiftSupportMetaData * (^HelpshiftSupportMetadataObjectBlock)(void);
typedef void (^HelpshiftSupportAppRatingAlertViewCompletionBlock)(HelpshiftSupportAlertToRateAppAction);

// A Reserved key (HelpshiftSupportCustomMetadataKey) constant to be used in options dictionary of showFAQs, showConversation, showFAQSection, showSingleFAQ to
// provide a dictionary for custom data to be attached along with new conversations.
//
// If you want to attach custom data along with new conversation, use this constant key and a dictionary value containing the meta data key-value pairs
// and pass it in withOptions param before calling any of the 4 support APIs.
//
// Available in SDK version 5.0.0 or later
//
// Example usages:
//  NSDictionary *metaDataWithTags = @{@"usertype": @"paid", @"level":@"7", @"score":@"12345", HelpshiftSupportTagsKey:@[@"feedback",@"paid user",@"v4.1"]};
//  [[Helpshift sharedInstance] showFAQs:self withOptions:@{@"gotoConversationAfterContactUs":@"YES", HelpshiftSupportCustomMetadataKey: metaDataWithTags}];
//
//  NSDictionary *metaData = @{@"usertype": @"paid", @"level":@"7", @"score":@"12345"]};
//  [[Helpshift sharedInstance] showConversation:self withOptions:@{HelpshiftSupportCustomMetadataKey: metaData}];
//
extern NSString *const HelpshiftSupportCustomMetadataKey;


// A Reserved key (HelpshiftSupportTagsKey) constant to be used with metadataBlock (of type NSDictionary) to pass NSArray (of type only NSStrings)
// which get interpreted at server and added as Tags for the issue being reported.
// If an object in NSArray is not of type NSString then the object will be removed from Tags and will not be added for the issue.
//
// Available in SDK version 5.0.0 or later
// Example usage 1:
//    [Helpshift metadataWithBlock:^(void){
//        return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"feedback", @"paid user",nil], HelpshiftSupportTagsKey, nil];
//    }];
// Example usage 2 (Available in SDK version 5.0.0 or later):
//    NSDictionary *metaData = @{@"usertype": @"paid", @"level":@"7", @"score":@"12345", HelpshiftSupportTagsKey:@[@"feedback",@"paid user",@"v4.1"]};
//    [[Helpshift sharedInstance] showConversation:self withOptions:@{HelpshiftSupportCustomMetadataKey: metaData}];
//
extern NSString *const HelpshiftSupportTagsKey;

// String constant to check which type of message you get in userRepliedToConversationWithMessage: delegate.
// When you use userRepliedToConversationWithMessage: delegate, you can check the type of message user replied with.
// When user replied with text message you will get that message string in delegate method.
// Example usage 1:
// - (void) userRepliedToConversationWithMessage:(NSString *)newMessage {
//   if ([newMessage isEqualToString:HelpshiftSupportUserAcceptedTheSolution]) {
//    // do something here
//    }
// }

static NSString *HelpshiftSupportUserAcceptedTheSolution = @"User accepted the solution";
static NSString *HelpshiftSupportUserRejectedTheSolution = @"User rejected the solution";
static NSString *HelpshiftSupportUserSentScreenShot = @"User sent a screenshot";
static NSString *HelpshiftSupportUserReviewedTheApp = @"User reviewed the app";


static NSString *HelpshiftSupportConversationFlow = @"conversationFlow";
static NSString *HelpshiftSupportFAQsFlow = @"faqsFlow";
static NSString *HelpshiftSupportFAQSectionFlow = @"faqSectionFlow";
static NSString *HelpshiftSupportSingleFAQFlow = @"singleFaqFlow";

/**
 * This document describes the API exposed by the Helpshift SDK (4.x) which the developers can use to integrate Helpshift support into their iOS applications. If you want documentation regarding how to use the various features provided by the Helpshift SDK, please visit the [developer docs](http://developers.helpshift.com/)
 */

@protocol HelpshiftSupportDelegate;

@interface HelpshiftSupport : NSObject <HsApiProvider>
{
    id <HelpshiftSupportDelegate> delegate;
}

@property (nonatomic, retain) id<HelpshiftSupportDelegate> delegate;

/** Returns an instance of Helpshift
 *
 * When calling any Helpshift instance method you must use sharedInstance. For example to call showSupport: you must call it like [[Helpshift sharedInstance] showSupport:self];
 *
 * Available in SDK version 5.0.0 or later
 */
+ (HelpshiftSupport *) sharedInstance;

/** To pause and restart the display of inapp notification
 *
 * When this method is called with boolean value YES, inapp notifications are paused and not displayed.
 * To restart displaying inapp notifications pass the boolean value NO.
 *
 * @param pauseInApp the boolean value to pause/restart inapp nofitications
 *
 * Available in SDK version 5.0.0 or later
 */
+ (void) pauseDisplayOfInAppNotification:(BOOL)pauseInApp;

/** Change the SDK language. By default, the device's prefered language is used.
 *  If a Helpshift session is already active at the time of invocation, this call will fail and will return false.
 *
 * @param languageCode the string representing the language code. For example, use 'fr' for French.
 *
 * @return BOOL indicating wether the specified language was applied. In case the language code is incorrect or
 * the corresponding localization file was not found, bool value of false is returned and the default language is used.
 *
 * Available in SDK version 5.0.0 or later
 */
+ (BOOL) setSDKLanguage:(NSString *)languageCode;

/** Show the helpshift conversation screen (with Optional Arguments)
 *
 * To show the Helpshift conversation screen with optional arguments you will need to pass the name of the viewcontroller on which the conversation screen will show up and an options dictionary. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param viewController viewController on which the helpshift report issue screen will show up.
 * @param optionsDictionary the dictionary which will contain the arguments passed to the Helpshift conversation session (that will start with this method call).
 *
 * Please check the docs for available options.
 *
 * Available in SDK version 5.0.0 or later
 */
+ (void) showConversation:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/** Show the helpshift conversation screen (with Optional Arguments)
 *
 * To show the Helpshift conversation screen with optional arguments you will need to pass the name of the viewcontroller on which the conversation screen will show up and an API config object. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param viewController viewController on which the helpshift report issue screen will show up.
 * @param configObject an API config object which will contain the arguments passed to the Helpshift conversation session (that will start with this method call).
 *
 * Please check the docs for available options.
 *
 * @available Available in SDK version 5.7.0 or later
 */
+ (void) showConversation:(UIViewController *)viewController withConfig:(HelpshiftAPIConfig *)configObject;

/** Show the support screen with only the faqs (with Optional Arguments)
 *
 * To show the Helpshift screen with only the faq sections with search with optional arguments, you can use this api. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param viewController viewController on which the helpshift faqs screen will show up.
 * @param optionsDictionary the dictionary which will contain the arguments passed to the Helpshift faqs screen session (that will start with this method call).
 *
 * Please check the docs for available options.
 *
 * Available in SDK version 5.0.0 or later
 */

+ (void) showFAQs:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/** Show the support screen with only the faqs (with Optional Arguments)
 *
 * To show the Helpshift screen with only the faq sections with search with optional arguments, you can use this api. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param viewController viewController on which the helpshift faqs screen will show up.
 * @param configObject an API config object which will contain the arguments passed to the Helpshift faqs screen session (that will start with this method call).
 *
 * Please check the docs for available options.
 *
 * @available Available in SDK version 5.7.0 or later
 */

+ (void) showFAQs:(UIViewController *)viewController withConfig:(HelpshiftAPIConfig *)configObject;


/** Show the helpshift screen with faqs from a particular section
 *
 * To show the Helpshift screen for showing a particular faq section you need to pass the publish-id of the faq section and the name of the viewcontroller on which the faq section screen will show up. For example from inside a viewcontroller you can call the Helpshift faq section screen by passing the argument “self” for the viewController parameter. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param faqSectionPublishID the publish id associated with the faq section which is shown in the FAQ page on the admin side (__yourcompanyname__.helpshift.com/admin/faq/).
 * @param viewController viewController on which the helpshift faq section screen will show up.
 * @param optionsDictionary the dictionary which will contain the arguments passed to the Helpshift session (that will start with this method call).
 *
 * Available in SDK version 5.0.0 or later
 */

+ (void) showFAQSection:(NSString *)faqSectionPublishID withController:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/** Show the helpshift screen with faqs from a particular section
 *
 * To show the Helpshift screen for showing a particular faq section you need to pass the publish-id of the faq section and the name of the viewcontroller on which the faq section screen will show up. For example from inside a viewcontroller you can call the Helpshift faq section screen by passing the argument “self” for the viewController parameter. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param faqSectionPublishID the publish id associated with the faq section which is shown in the FAQ page on the admin side (__yourcompanyname__.helpshift.com/admin/faq/).
 * @param viewController viewController on which the helpshift faq section screen will show up.
 * @param configObject an API config object which will contain the arguments passed to the Helpshift session (that will start with this method call).
 *
 * @available Available in SDK version 5.7.0 or later
 */

+ (void) showFAQSection:(NSString *)faqSectionPublishID withController:(UIViewController *)viewController withConfig:(HelpshiftAPIConfig *)configObject;

/** Show the helpshift screen with a single faq
 *
 * To show the Helpshift screen for showing a single faq you need to pass the publish-id of the faq and the name of the viewcontroller on which the faq screen will show up. For example from inside a viewcontroller you can call the Helpshift faq section screen by passing the argument “self” for the viewController parameter. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param faqPublishID the publish id associated with the faq which is shown when you expand a single FAQ (__yourcompanyname__.helpshift.com/admin/faq/)
 * @param viewController viewController on which the helpshift faq section screen will show up.
 * @param optionsDictionary the dictionary which will contain the arguments passed to the Helpshift session (that will start with this method call).
 *
 * Available in SDK version 5.0.0 or later
 */

+ (void) showSingleFAQ:(NSString *)faqPublishID withController:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/** Show the helpshift screen with a single faq
 *
 * To show the Helpshift screen for showing a single faq you need to pass the publish-id of the faq and the name of the viewcontroller on which the faq screen will show up. For example from inside a viewcontroller you can call the Helpshift faq section screen by passing the argument “self” for the viewController parameter. If you do not want to pass any options then just pass nil which will take on the default options.
 *
 * @param faqPublishID the publish id associated with the faq which is shown when you expand a single FAQ (__yourcompanyname__.helpshift.com/admin/faq/)
 * @param viewController viewController on which the helpshift faq section screen will show up.
 * @param configObject an API config object which will contain the arguments passed to the Helpshift session (that will start with this method call).
 *
 * @available Available in SDK version 5.7.0 or later
 */

+ (void) showSingleFAQ:(NSString *)faqPublishID withController:(UIViewController *)viewController withConfig:(HelpshiftAPIConfig *)configObject;

/** Show alert for app rating
 *
 * To manually show an alert for app rating, you need automated reviews disabled in admin.
 * Also, if there is an ongoing conversation, the review alert will not show up.
 *
 * Available in SDK version 5.0.0 or later
 */
+ (void) showAlertToRateAppWithURL:(NSString *)url withCompletionBlock:(HelpshiftSupportAppRatingAlertViewCompletionBlock)completionBlock;

/** Set an user identifier for your users.
 *
 * This is part of additional user configuration. The user identifier will be passed through to the admin dashboard as "User ID" under customer info.
 *  @param userIdentifier A string to identify your users.
 *
 *  Available in SDK version 5.0.0 or later
 */

+ (void) setUserIdentifier:(NSString *)userIdentifier;

/** Add extra debug information regarding user-actions.
 *
 * You can add additional debugging statements to your code, and see exactly what the user was doing right before they reported the issue.
 *
 *  @param breadCrumbString The string containing any relevant debugging information.
 *
 *  Available in SDK version 5.0.0 or later
 */

+ (void) leaveBreadCrumb:(NSString *)breadCrumbString;

/** Provide a block which returns a dictionary for custom meta data to be attached along with new conversations
 *
 * If you want to attach custom data along with any new conversation, use this api to provide a block which accepts zero arguments and returns an NSDictionary containing the meta data key-value pairs. Everytime an issue is reported, the SDK will call this block and attach the returned meta data dictionary along with the reported issue. Ideally this metaDataBlock should be provided before the user can file an issue.
 *
 *  @param metadataBlock a block variable which accepts zero arguments and returns an NSDictionary.
 *
 *  Available in SDK version 5.0.0 or later
 */

+ (void) setMetadataBlock:(HelpshiftSupportMetadataBlock)metadataBlock;

/** Provide a block which returns a HelpshiftSupportMetadataObject for custom meta data to be attached along with new conversations
 *
 * If you want to attach custom data along with any new conversation, use this api to provide a block which accepts zero arguments and returns an HelpshiftSupportMetadataObject containing the meta data dictionary. Everytime an issue is reported, the SDK will call this block and attach the returned HelpshiftSupportMetadataObject along with the reported issue. Ideally this metaDataBlock should be provided before the user can file an issue.
 *
 *  @param HelpshiftSupportMetadataObjectBlock a block variable which accepts zero arguments and returns an HelpshiftSupportMetadataObject.
 *
 *  @available Available in SDK version 5.7.0 or later
 */

+ (void) setMetadataObjectBlock:(HelpshiftSupportMetadataObjectBlock)metadataBlock;

/** Get a boolean value that indicates if there is any active converation in the SDK currently.
 *
 *  Returns YES if there an active conversation going on otherwise returns NO.
 *  @available Available in SDK version 5.10.0 or later
 */

+ (BOOL) isConversationActive;

/** Get the notification count for replies to new conversations.
 *
 *
 * If you want to show your user notifications for replies on any ongoing conversation, you can get the notification count asynchronously by implementing the HelpshiftSupportDelegate in your respective .h and .m files.
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
 * Available in SDK version 5.0.0 or later
 */

+ (NSInteger) getNotificationCountFromRemote:(BOOL)isRemote;

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
 *  Available in SDK version 5.0.0 or later
 *
 */
+ (void) handleRemoteNotification:(NSDictionary *)notification withController:(UIViewController *)viewController;

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
 * Available in SDK version 5.0.0 or later
 *
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (void) handleLocalNotification:(UILocalNotification *)notification withController:(UIViewController *)viewController;
#pragma clang diagnostic pop
/** Clears Breadcrumbs list.
 *
 * Breadcrumbs list stores upto 100 latest actions. You'll receive those in every Issue.
 * If for some reason you want to clear previous messages, you can use this method.
 *
 * Available in SDK version 5.0.0 or later
 *
 */
+ (void) clearBreadCrumbs;

/** Close the current Helpshift session
 *
 * If currently any Helpshift session is active, this API will close that session.
 * Otherwise if any Helpshift session is not active, this API does nothing.
 *
 * Available in SDK version 5.0.0 or later
 *
 */
+ (void) closeHelpshiftSupportSession;

/**
 *  Let the Helpshift SDK handle the continue user activity delegate.
 *  This method should be called from the application's handleContinueUserActivity delegate.
 *  Currently this method is required for the FAQ integration with CoreSpotlight search to work correctly.
 *
 *  @param userActivity       useractivity object receieved in the delegate callback
 *  @param viewController     view controller on which Helpshift should show the FAQ detail screen.
 *  @param restorationHandler restoration handler received in the delegate callback
 *
 *  @return returns YES if Helpshift has handled the event, NO otherwise.
 */
+ (BOOL) handleContinueUserActivity:(NSUserActivity *)userActivity
    withController:(UIViewController *)viewController
    andRestorationHandler:(void (^)(NSArray *))restorationHandler;

/**
 *  This is a wrapper over NSLog. Use this API as a replacement over NSLog for the logs that need to be added as meta data while filing an issue.
 *  This API internally calls NSLog.
 *
 * @param logText the string to be logged.
 *
 * Available in SDK version 5.9.0 or later
 */
+ (void) log:(NSString *)format, ...;

#pragma mark Dynamic Forms

/**
 *  Use this method to create a list of custom 'flows' and present them in tabular form to the user.
 *  A flow consists of 1) The text to be displayed (like 'I think a player is cheating') and 2) The action to be invoked for this option (like 'showConversation:'). In this case besides calling the showConversation: method, Helpshfit will also add a tag ('I think a player is cheating', or any other custom tag) to the filed issue.
 *  These tags can later be used by you to gain insight as to how users are using your support.
 *  Actions supported by Dynamic forms: showConversation:, showFAQs:, showSingleFAQ:, showFAQSection: and showNextDynamicForm: (for nesting forms).
 *
 *  @param viewController The view controller on which Dynamic form will be presented.
 *  @param title          The title of the form.
 *  @param flows          A list of 'HsFlow' objects.
 *  @param configOptions  Config option that applies to Dynamic form itself (NOTE: this is not automatically applied to the flows). Currently the only config option applicable her is 'presentFullScreenOniPad' which can be 'yes' or 'no'
 *
 *  @return Returns YES if the data provided was valid to create a dynamic form, otherwise returns NO.
 */
+ (BOOL) showDynamicFormOnViewController:(UIViewController *)viewController withTitle:(NSString *)title andFlows:(NSArray *)flows withConfigOptions:(NSDictionary *)configOptions;

/**
 *  Use this method to create a list of custom 'flows' and present them in tabular form to the user.
 *  A flow consists of 1) The text to be displayed (like 'I think a player is cheating') and 2) The action to be invoked for this option (like 'showConversation:'). In this case besides calling the showConversation: method, Helpshfit will also add a tag ('I think a player is cheating', or any other custom tag) to the filed issue.
 *  These tags can later be used by you to gain insight as to how users are using your support.
 *  Actions supported by Dynamic forms: showConversation:, showFAQs:, showSingleFAQ:, showFAQSection: and showNextDynamicForm: (for nesting forms).
 *
 *  @param viewController The view controller on which Dynamic form will be presented.
 *  @param title          The title of the form.
 *  @param flows          A list of 'HsFlow' objects.
 *  @param configObject   API config object that applies to Dynamic form itself (NOTE: this is not automatically applied to the flows). Currently the only config option applicable her is 'presentFullScreenOniPad' which can be 'yes' or 'no'
 *
 *  @return Returns YES if the data provided was valid to create a dynamic form, otherwise returns NO.
 */
+ (BOOL) showDynamicFormOnViewController:(UIViewController *)viewController withTitle:(NSString *)title andFlows:(NSArray *)flows withConfig:(HelpshiftAPIConfig *)configObject;

/**
 *  Use this method to show a Dynamic form built from an NSDictionary.
 *
 *  @param viewController The view controller on which Dynamic form will be presented.
 *  @param title          The title of the form.
 *  @param flows      A list of NSDictionary objects.
 *  Following are the key/value pairs required in the dictionary
 *  1. "type" - this key should contain the type of flow. value should be one of the following :
 *   1. Support.FAQS_FLOW
 *   2. Support.CONVERSATION_FLOW
 *   3. Support.FAQ_SECTION_FLOW
 *   4. Support.SINGLE_FAQ_FLOW
 *  2. "title" - resource name of the title shown for the flow
 *  3. "data" - data required for the flow. its value should be as described below :
 *      for FAQ_SECTION_FLOW, "data" should contain string section id
 *      for SINGLE_FAQ_FLOW, "data" shoudl contain string faq id
 *      for FAQsFlow and ConversationFlow, no "data" is required
 *  4. "config" - it should be a HashMap which is used to pass as config to Support APIs.
 *      for DYNAMIC_FORM_FLOW, no "config" is required
 *
 *  @param configOptions  Config option that applies to Dynamic form itself (NOTE: this is not automatically applied to the flows). Currently the only config option applicable her is 'presentFullScreenOniPad' which can be 'yes' or 'no'
 *
 *  @return Returns YES if the data provided was valid to create a dynamic form, otherwise returns NO.
 */
+ (BOOL) showDynamicFormOnViewController:(UIViewController *)viewController withTitle:(NSString *)title andFlowsData:(NSArray *)flows withConfigOptions:(NSDictionary *)configOptions;


/**
 *  This is the push variant of showDynamicFormOnViewController:
 *  Use this method if you want to push the dynamic form to your navigation stack.
 *
 *  @param viewController The view controller on which Dynamic form will be pushed.
 *  @param title          The title of the form.
 *  @param flows          A list of 'HsFlow' objects.
 *
 *  @return Returns YES if the data provided was valid to create a dynamic form, otherwise returns NO.
 */
+ (BOOL) pushDynamicFormOnViewController:(UIViewController *)viewController withTitle:(NSString *)title andFlows:(NSArray *)flows;

/**
 *  Creates and returns the a Dynamic Form navigation controller. This is a variant of showDynamicFormOnViewController:
 *  Use this variant if you want to embed dynamic form in a UITabBarController
 *
 *  @param title The title of the form.
 *  @param flows A list of 'HsFlow' objects.
 *
 *  @return Returns a UINavigationController if the data provided was valid to create a dynamic form, otherwise returns nil.
 */
+ (UINavigationController *) dynamicFormWithTitle:(NSString *)title andFlows:(NSArray *)flows;

/**
 *  Create a flow object which launches the conversation view when tapped. Refer to showConversation: for more details.
 *
 *  @param displayText   Text to be displayed in the row.
 *  @param configOptions The config options to be passed to showConversation: method.
 *
 *  @return a flow object to be used for creating a dynamic form.
 */
+ (id) flowToShowConversationWithDisplayText:(NSString *)displayText
    andConfigOptions:(NSDictionary *)configOptions;

/**
 *  Create a flow object which launches the conversation view when tapped. Refer to showConversation: for more details.
 *
 *  @param displayText   Text to be displayed in the row.
 *  @param configObject  The API config object to be passed to showConversation: method.
 *
 *  @return a flow object to be used for creating a dynamic form.
 */
+ (id) flowToShowConversationWithDisplayText:(NSString *)displayText
    andConfig:(HelpshiftAPIConfig *)configObject;

/**
 *  Create a flow object which shows all the FAQs when tapped. Refer to showFAQs: for more details.
 *
 *  @param displayText      Text to be displayed in the row.
 *  @param configOptions    The config options to be passed to showFAQSection: method.
 *
 *  @return a flow object to be used for creating a dynamic form.
 */
+ (id) flowToShowFAQsWithDisplayText:(NSString *)displayText
    andConfigOptions:(NSDictionary *)configOptions;

/**
 *  Create a flow object which shows all the FAQs when tapped. Refer to showFAQs: for more details.
 *
 *  @param displayText      Text to be displayed in the row.
 *  @param configObject     The API config object to be passed to showFAQSection: method.
 *
 *  @return a flow object to be used for creating a dynamic form.
 */
+ (id) flowToShowFAQsWithDisplayText:(NSString *)displayText
    andConfig:(HelpshiftAPIConfig *)configObject;

/**
 *  Create a flow object which launches a FAQ section when tapped. Refer to showFAQSection: for more details.
 *
 *  @param sectionPublishId The Publish-Id of the FAQ section.
 *  @param displayText      Text to be displayed in the row.
 *  @param configOptions    The config options to be passed to showFAQSection: method.
 *
 *  @return a flow object to be used for creating a dynamic form.
 */
+ (id) flowToShowFAQSectionForPublishId:(NSString *)sectionPublishId
    withDisplayText:(NSString *)displayText
    andConfigOptions:(NSDictionary *)configOptions;

/**
 *  Create a flow object which launches a FAQ section when tapped. Refer to showFAQSection: for more details.
 *
 *  @param sectionPublishId The Publish-Id of the FAQ section.
 *  @param displayText      Text to be displayed in the row.
 *  @param displayText      The config API object to be passed to showFAQSection: method.
 *
 *  @return a flow object to be used for creating a dynamic form.
 */
+ (id) flowToShowFAQSectionForPublishId:(NSString *)sectionPublishId
    withDisplayText:(NSString *)displayText
    andConfig:(HelpshiftAPIConfig *)configObject;

/**
 *  Create a flow object which launches a single FAQ when tapped. Refer to showSingleFAQ: for more details.
 *
 *  @param FAQPublishId     The Publish-Id of the FAQ.
 *  @param displayText      Text to be displayed in the row.
 *  @param configOptions    The config options to be passed to showSingleFAQ: method.
 *
 *  @return a flow object to be used for creating a dynamic form.
 */
+ (id) flowToShowSingleFAQForPublishId:(NSString *)FAQPublishId
    withDisplayText:(NSString *)displayText
    andConfigOptions:(NSDictionary *)configOptions;

/**
 *  Create a flow object which launches a single FAQ when tapped. Refer to showSingleFAQ: for more details.
 *
 *  @param FAQPublishId     The Publish-Id of the FAQ.
 *  @param displayText      Text to be displayed in the row.
 *  @param configOptions    The config options to be passed to showSingleFAQ: method.
 *
 *  @return a flow object to be used for creating a dynamic form.
 */
+ (id) flowToShowSingleFAQForPublishId:(NSString *)FAQPublishId
    withDisplayText:(NSString *)displayText
    andConfig:(HelpshiftAPIConfig *)configObject;

/**
 *  Use this method to nest a dynamic form within another dynamic form. Basically this method takes a list of 'flows' and combines them into a single 'flow' (the next dynamic form).
 *
 *  @param nextDynamicFormFlows A list of 'flow' objects that will show up as the next dynamic form when this flow is tapped.
 *  @param displayText      Text to be displayed in the row.
 *
 *  @return a flow object to be used for creating a dynamic form.
 */
+ (id) flowToShowNestedDynamicFormWithFlows:(NSArray *)nextDynamicFormFlows
    withDisplayText:(NSString *)displayText;

/**
 *  Use this method to create a flow that performs a custom action when tapped.
 *
 *  @param target      The target on which the selector will be called.
 *  @param selector    The selector that needs to be invoked.
 *  @param optionalObject      An optional object that needs to be passed to the selector.
 *  @param displayText Text to be displayed in the row.
 *
 *  @return a flow object.
 */
+ (id) flowToPerformCustomActionOnTarget:(id)target
    andSelector:(SEL)selector
    withOptionalObject:(id)optionalObject
    withDisplayText:(NSString *)displayText;

#pragma mark - Deprecated APIs

- (BOOL) showDynamicFormOnViewController:(UIViewController *)viewController withTitle:(NSString *)title andFlows:(NSArray *)flows withConfigOptions:(NSDictionary *)configOptions __deprecated;

- (BOOL) pushDynamicFormOnViewController:(UIViewController *)viewController withTitle:(NSString *)title andFlows:(NSArray *)flows __deprecated;

- (UIViewController *) dynamicFormWithTitle:(NSString *)title andFlows:(NSArray *)flows __deprecated;

@end

@protocol HelpshiftSupportDelegate <NSObject>

/** Delegate method call that should be implemented if you are calling getNotificationCountFromRemote:YES
 * @param count Returns the number of unread messages for the ongoing conversation
 *
 * Available in SDK version 5.0.0 or later
 */

- (void) didReceiveNotificationCount:(NSInteger)count;

@optional
/** Optional delegate method that is called when the a Helpshift session begins.
 *
 *
 * Helpshift session is any Helpshift support screen opened via showFAQ:, showConversation: or other API calls.
 * Whenever one of these APIs launches a view on screen, this method is invoked.
 *
 *  Available in SDK version 5.0.0 or later
 */
- (void) helpshiftSupportSessionHasBegun;

/** Optional delegate method that is called when the Helpshift session ends.
 *
 *
 * Helpshift session is any Helpshift support screen opened via showSupport: or other API calls.
 * Whenever the user closes that support screen and returns back to the app this method is invoked.
 *
 *  Available in SDK version 5.0.0 or later
 */
- (void) helpshiftSupportSessionHasEnded;

/** Optional delegate method that is called when a Helpshift inapp notification arrives and is shown
 *  @param count Returns the number of messages that has arrived via inapp notification.
 *
 * Available in SDK version 5.0.0 or later
 */
- (void) didReceiveInAppNotificationWithMessageCount:(NSInteger)count;

/** Optional delegate method that is called when new conversation get started via any Helpshift API Ex:- showFaq:, showConversation:,etc
 * @param newConversationMessage Return first message of new conversation.
 * Available in SDK version 5.0.0 or later
 */
- (void) newConversationStartedWithMessage:(NSString *)newConversationMessage;

/**
 *  Optional delegate method that gets called when the current conversation is ended.
 * Available in SDK version 5.10.0 or later
 */
- (void) conversationEnded;

/** Optional delegate method that is called when user reply on current open conversation via any Helpshift API Ex:- showFaq:, showConversation:, etc
 * @param newMessage Return reply message on open conversation.
 * Available in SDK version 5.0.0 or later
 */
- (void) userRepliedToConversationWithMessage:(NSString *)newMessage;

/**Optional delegate method that is called when user complete customer satisfaction survey after issue getting resolved.
 * @param rating Return the rating of customer satisfaction survey.
 * @param feedback Return text which user added in customer satisfaction survey.
 *
 * Available in SDK version 5.0.0 or later.
 */
- (void) userCompletedCustomerSatisfactionSurvey:(NSInteger)rating withFeedback:(NSString *)feedback;

/** Optional delegate method that is called when the user taps an downloaded attachment file to view it.
 *  @return If the app chooses to display the attachment file itself, return true
 *          If the app does not wish to handle the attachment, return false. In this case, the SDK will display the attachment
 *  @param fileLocation Returns the location on the downloaded attachment file.
 *         parentViewController Returns SDK's top view controller that the app can use to present its view.
 *
 * Available in SDK version 5.0.0 or later
 */
- (BOOL) displayAttachmentFileAtLocation:(NSURL *)fileLocation onViewController:(UIViewController *)parentViewController;

/**
 *  Optional delegate method that gets called when the user clicks on a search entry corresponding to your application's FAQs in
 *  CoreSpotlight search.
 *
 *  @return Dictionary with all the config options that the developer wants to pass to the showSingleFAQ API call.
 *  Available in SDK version 5.1.0 or later.
 */
- (NSDictionary *) configForFAQViaSearch;

@end
