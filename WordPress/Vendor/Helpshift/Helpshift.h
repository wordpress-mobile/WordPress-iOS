/*
 *    Helpshift.h
 *    SDK Version 5.10.1
 *
 *    Get the documentation at http://www.helpshift.com/docs
 *
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum HSAlertToRateAppAction
{
    HS_RATE_ALERT_CLOSE = 0,
    HS_RATE_ALERT_FEEDBACK,
    HS_RATE_ALERT_SUCCESS,
    HS_RATE_ALERT_FAIL
} HSAlertToRateAppAction __deprecated;

typedef NSDictionary * (^metadataBlock)(void);
typedef void (^AppRatingAlertViewCompletionBlock)(HSAlertToRateAppAction);

/**
 *  A Reserved key (HSCustomMetadataKey) constant to be used in options dictionary of showFAQs, showConversation, showFAQSection, showSingleFAQ to provide a dictionary for custom data to be attached along with new conversations. If you want to attach custom data along with new conversation, use this constant key and a dictionary value containing the meta data key-value pairs and pass it in withOptions param before calling any of the 4 support APIs.
 *
 *  @available Version 4.2.0 or later
 *
 *  Example usage -
 *  NSDictionary *metaDataWithTags = @{@"usertype": @"paid", @"level":@"7", @"score":@"12345", HSTagsKey:@[@"feedback",@"paid user",@"v4.1"]};
 * [[Helpshift sharedInstance] showFAQs:self withOptions:@{@"gotoConversationAfterContactUs":@"YES", HSCustomMetadataKey: metaDataWithTags}];
 *
 * NSDictionary *metaData = @{@"usertype": @"paid", @"level":@"7", @"score":@"12345"]};
 * [[Helpshift sharedInstance] showConversation:self withOptions:@{HSCustomMetadataKey: metaData}];
 */
extern NSString *const HSCustomMetadataKey __deprecated;

/**
 *  A Reserved key (HSTagsKey) constant to be used with metadataBlock (of type NSDictionary) to pass NSArray (of type only NSStrings) which get interpreted at server and added as Tags for the issue being reported.
 *  If an object in NSArray is not of type NSString then the object will be removed from Tags and will not be added for the issue.
 *
 *  Example usage - (Version 3.2.0 or later)
 *  [Helpshift metadataWithBlock:^(void){
 * return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"feedback", @"paid user",nil], HSTagsKey, nil];
 * }];
 *
 *  Example usage - (Version 4.2.0 or later)
 *  NSDictionary *metaData = @{@"usertype": @"paid", @"level":@"7", @"score":@"12345", HSTagsKey:@[@"feedback",@"paid user",@"v4.1"]};
 * [[Helpshift sharedInstance] showConversation:self withOptions:@{HSCustomMetadataKey: metaData}];
 */

extern NSString *const HSTagsKey __deprecated;

/**
 *  Types of auto message responses generated on user actions. These values can be used in your userRepliedToConversationWithMessage: delegate call. If the user replied with a custom message, then that string will be returned instead.
 *
 *  Example usage -
 *  - (void) userRepliedToConversationWithMessage:(NSString *)newMessage {
 *      if ([newMessage isEqualToString:HSUserAcceptedTheSolution]) {
 *          //Do something
 *      }
 *  }
 */

__deprecated static NSString *HSUserAcceptedTheSolution = @"User accepted the solution";
__deprecated static NSString *HSUserRejectedTheSolution = @"User rejected the solution";
__deprecated static NSString *HSUserSentScreenShot = @"User sent a screenshot";
__deprecated static NSString *HSUserReviewedTheApp = @"User reviewed the app";

__deprecated @protocol HelpshiftDelegate;
__deprecated @interface Helpshift : NSObject
@property (nonatomic, strong) id<HelpshiftDelegate> delegate;

/**
 *  Initialise Helpshift. This invocation typically needs to happen in your application:didFinishLaunchingWithOptions: method.
 *
 *  @param apiKey            Your developer API Key.
 *  @param domainName        Your domain name (without 'http:/' or forward slashes)
 *  @param appID             Unique ID assigned to your app.
 *
 *  @available Version 4.0.0 or later
 */
+ (void) installForApiKey:(NSString *)apiKey domainName:(NSString *)domainName appID:(NSString *)appID;

/**
 *  Initialise Helpshift. This invocation typically needs to happen into your applications didFinishLaunchingWithOptions: method.
 *
 *  @param apiKey            Your developer API Key.
 *  @param domainName        Your domain name (without 'http:/' or forward slashes)
 *  @param appID             Unique ID assigned to your app.
 *  @param optionsDictionary Optional dictionary containing Helpshift's configuration options and their values.
 *                           Example: @{@"enableInAppNotification":@"no"}
 *
 *  @available Version 4.0.0 or later
 */
+ (void) installForApiKey:(NSString *)apiKey domainName:(NSString *)domainName appID:(NSString *)appID withOptions:(NSDictionary *)optionsDictionary;

/**
 *  Shared instance of Helpshift class. Use this instance to make all subsequent calls like showConversation:
 *
 *  @return Shared Helpshift instance object.
 *
 *  @available Version 1.0.0 or later
 */
+ (Helpshift *) sharedInstance;

/**
 *  Pause/resume the display of in-app notifications.
 *
 *  @param pauseInApp If yes, the display of in-app notification is paused. To resume, pauseInApp needs to be set to no.
 *
 *  @available Version 4.3.0 or later
 */
+ (void) pauseDisplayOfInAppNotification:(BOOL)pauseInApp;

/**
 *  Change the SDK language manually. By default, Helpshift picks up the device language.
 *  If there is no localisation found for the language code or if a Helpshift session is already active, this method returns false.
 *  Note: Switching between RTL and LTR languages will change the actual language used but the UI controls will not change as this requires OS support.
 *
 *  @param languageCode The string representing the language code. (like "fr" for french)
 *
 *  @return A bool indicating wether the language change was successful. In case the language code passed could not be associated with any localisation available this will be false. SDK will fall back to the default language in this case.
 *
 *  @available Version 4.11.0 or later
 */
- (BOOL) setSDKLanguage:(NSString *)languageCode;

/**
 *  Display the conversation screen.
 *
 *  @param viewController      The view controller on which Helpshift's view stack will be presented.
 *  @param optionsDictionary   Helpshift configuration options relevant to this method call. Pass nil, if not applicable.
 *
 *  @available Version 4.0.0 or later
 */

- (void) showConversation:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/**
 *  Display the FAQs.
 *
 *  @param viewController      The view controller on which Helpshift's view stack will be presented.
 *  @param optionsDictionary   Helpshift configuration options relevant to this method call. Pass nil, if not applicable.
 *
 *  @available Version 2.0.0 or later
 */
- (void) showFAQs:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/**
 *  Display an FAQ section to the user. This view will have a close button to take user back to the app.
 *
 *  @param faqSectionPublishID The publish-id of the FAQ section.
 *  @param viewController      The view controller on which Helpshift's view stack will be presented.
 *  @param optionsDictionary   Helpshift configuration options relevant to this method call. Pass nil, if not applicable.
 *
 *  @available Version 2.0.0 or later
 */
- (void) showFAQSection:(NSString *)faqSectionPublishID withController:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/**
 *  Display a single FAQ to the user. This view will have a close button to take user back to the app.
 *
 *  @param faqPublishID      The publish-id of the FAQ.
 *  @param viewController    The view controller on which Helpshift's view stack will be presented.
 *  @param optionsDictionary Helpshift configuration options relevant to this method call. Pass nil, if not applicable.
 *
 *  @available Version 4.0.0 or later
 */
- (void) showSingleFAQ:(NSString *)faqPublishID withController:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/**
 *  Show the App rating view alert.
 *  Note that automated reviews need to be disabled in the admin to make this call effective. Also, if there is an ongoing conversation, the review alert will not show up.
 *  @param url             The App store URL to redirect to.
 *  @param completionBlock The completion block.
 *
 *  @available Version 4.4.0 or later
 */
+ (void) showAlertToRateAppWithURL:(NSString *)url withCompletionBlock:(AppRatingAlertViewCompletionBlock)completionBlock;

/**
 *  Set an identifier for the default user.
 *  This is part of additional user configuration. The user identifier will be passed through to the admin dashboard as "User ID" under customer info.
 *  @param userIdentifier A unique string identifying the default user.
 *
 *  @available Version 1.0.0 or later
 */
+ (void) setUserIdentifier:(NSString *)userIdentifier;

/**
 *  Set the name and email of the current logged in user. If you are not using the login API, the current logged in user will the the default user.
 *  The information provided here will be used to pre populate the conversation screen. Pass nil to clear the existing values.
 *
 *  @param name  NSString representing user's name.
 *  @param email NSString representing user's email.
 *
 *  @available Version 4.0.0 or later
 */
+ (void) setName:(NSString *)name andEmail:(NSString *)email;

/**
 *  Add extra information about user actions. You can add details about system state or user actions which can later be used to see what was going on before an issue was reported.
 *  @param breadCrumbString The string to be sent to server.
 *
 *  @available Version 1.0.0 or later
 */
+ (void) leaveBreadCrumb:(NSString *)breadCrumbString;

/**
 *  A block which returns a dictionary containing the custom meta data to be attached along with new conversations
 *  If you want to attach custom data along with any new conversation, use this api to provide a block which accepts zero arguments and returns an NSDictionary containing the meta data key-value pairs. Every time an issue is reported, the SDK will call this block and attach the returned meta data dictionary along with the reported issue. Ideally this metaDataBlock should be provided before the user can file an issue.
 *  @param metadataBlock A block variable which accepts zero arguments and returns an NSDictionary.
 *
 *  @available Version 4.0.0 or later
 */
+ (void) setMetadataBlock:(metadataBlock)metadataBlock;

/**
 *  Get the number of unread messages for current user. This comes in two flavours depending on the value used for 'isRemote'.
 *
 *  If you want to get the unread messages available locally in the SDK for the current issue, set 'isRemote' to false. In this case the value is immediately returned.
 *  if you want Helpshift to get the number of unread messages from the servers, set 'isRemote' to true. In this case the value returned is -1. A server call is made to fetch the value. When the server call is successful, the value is passed to you via the didReceiveNotificationCount: delegate. To receive this call back make sure you are registered as the delegate: [[Helpshift sharedInstance] setDelegate:self];
 *  @param isRemote Should the value be returned from local data or server.
 *
 *  @return if isRemote was false, the number of unread messages for current issue is retuned. If isRemote was true, -1 is returned.
 *
 *  @available Version 4.0.0 or later
 */
- (NSInteger) getNotificationCountFromRemote:(BOOL)isRemote;

/**
 *  Use this method to register the device for push notifications.
 *  To enable push notifications from Helpshift (like when an agent replies to user's issue), pass the deviceToken received in your application delegate's didRegisterForRemoteNotificationsWithDeviceToken: method.
 *
 * Example usage -
 *  - (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
 *  {
 *      [[Helpshift sharedInstance] registerDeviceToken:deviceToken];
 *  }
 *
 *  @param deviceToken Token received from APNS.
 */
- (void) registerDeviceToken:(NSData *)deviceToken;

#ifdef UNITY_SUPPORT
- (void) registerDeviceTokenForUnity:(NSString *)deviceTokenData;
#endif

/**
 *  Pass control to Helpshift for handling a push notification.
 *  In your application delegate's didReceiveRemoteNotification: method, check if "origin" is "helpshift". If yes, you should call this method.
 *
 *  Example usage -
 *  - (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
 *  {
 *      if ([[notification.userInfo objectForKey:@"origin"] isEqualToString:@"helpshift"]) {
 *          [[Helpshift sharedInstance] handleRemoteNotification:userInfo withController:self.viewController];
 *      }
 *  }
 *
 *  @param notification   The NSDictionary object received.
 *  @param viewController The current view controller on which Helpshift's view stack will shown.
 *
 *  @available Version 4.0.0 or later
 */
- (void) handleRemoteNotification:(NSDictionary *)notification withController:(UIViewController *)viewController;

/**
 *  Pass control to Helpshift for handling a local notification.
 *  In your application delegate's didReceiveLocalNotification: method, check if "origin" is "helpshift". If yes, you should call this method.
 *
 *  Example usage -
 *  - (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
 *  {
 *      if ([[notification.userInfo objectForKey:@"origin"] isEqualToString:@"helpshift"]) {
 *          [[Helpshift sharedInstance] handleLocalNotification:notification withController:self.viewController];
 *      }
 *  }
 *
 *  @param notification   The UILocalNotification object received.
 *  @param viewController The current view controller on which Helpshift's view stack will shown.
 *
 *  @available Version 2.4.0 or later
 */
- (void) handleLocalNotification:(UILocalNotification *)notification withController:(UIViewController *)viewController;

/**
 *  Clears the current Breadcrumbs.
 *  Breadcrumbs is a list of user's latest 100 actions. Use the leaveBreadCrumb: method to leave a Breadcrumb.
 *
 *  @available Version 2.3.0 or later
 */
- (void) clearBreadCrumbs;

/**
 *  Closes the Helpshift session. Ignored if a Helpshift session is not active.
 *  Helpshift's view stack is popped and user returns to the app.
 *
 *  @available Version 4.8.0 or later
 */
- (void) closeHelpshiftSession;

/**
 *  Logs in a user to Helpshift. This is useful in multi-login scenarios where more than one person might use the app.
 *  Creating individual logins for each user ensures that their issues remain separate. This method will not work if a Helpshift session is already active.
 *
 *  @param identifier A unique string to identify a user.
 *  @param name       Name of the user. This will be used to pre populate the 'name' field on issue filing screen. (optional, please pass nil if you want to ignore)
 *  @param email      Email of the user. This will be used to pre populate the 'email' field on issue filing screen. (optional, please pass nil if you want to ignore)
 *
 *  @available Version 4.10.0 or later
 */
+ (void) loginWithIdentifier:(NSString *)identifier withName:(NSString *)name andEmail:(NSString *)email;

/**
 *  Logs out the current user and falls back to default login. If the current logged is user was already the default profile, this call is ignored.
 *  This call is ignored if a Helpshift session is already active.
 *
 *  @available Version 4.10.0 or later
 */
+ (void) logout;


@end

__deprecated @protocol HelpshiftDelegate <NSObject>

/**
 *  This delegate is the response to the 'getNotificationCountFromRemote:' method with 'isRemote' set to YES. It provides the number of unread messages in the current conversation.
 *  @param count Number of unread messages in the current conversation as indicated by the server.
 *
 *  @available Version 4.0.0 or later
 */
- (void) didReceiveNotificationCount:(NSInteger)count;

@optional

/**
 *  Optional delegate method that is called when a Helpshift session begins.
 *  When a Helpshift session begins (via showFAQ:, showConversation:, etc.), Helpshift's view stack is presented on top of the app's view controller.
 *
 *  @available Version 4.10.1 or later
 */
- (void) helpshiftSessionHasBegun;

/**
 *  Optional delegate method that will be called when Helpshift's session ends.
 *  When a Helpshift session ends, the Helpshift view pops and user is taken back to the app.
 *
 *  @available Version 1.4.3 or later
 */
- (void) helpshiftSessionHasEnded;

/**
 *  Optional delegate method that is called when a Helpshift in-app notification is received and displayed.
 *  In-app notifications are push notifications that are received when the app is in the foreground.
 *
 *  @param count The number of messages contained in the notification.
 *
 *  @available Version 4.3.0 or later
 */
- (void) didReceiveInAppNotificationWithMessageCount:(NSInteger)count;

/**
 * Optional delegate method that is called when the user starts a new conversation via any Helpshift APIs (showFaq:, showConversation:, etc.)
 * @param newConversationMessage First message of new conversation.
 *
 * @available Version 4.10.0 or later
 */
- (void) newConversationStartedWithMessage:(NSString *)newConversationMessage;

/**
 * Optional delegate method that is called when a user sends a message on the current open conversation.
 * @param newMessage User's message.
 *
 * @available Version 4.10.0 or later
 */
- (void) userRepliedToConversationWithMessage:(NSString *)newMessage;

/**
 * Optional delegate method that is called when user complete customer satisfaction survey. The customer satisfaction survey is shown after an issue gets resolved.
 * @param rating User rating in the customer satisfaction survey.
 * @param feedback The feedback text added by user in customer satisfaction survey.
 *
 * @available Version 4.10.1 or later.
 */
- (void) userCompletedCustomerSatisfactionSurvey:(NSInteger)rating withFeedback:(NSString *)feedback;

/**
 * Optional delegate method that is called when the user taps an downloaded attachment file to view it.
 *  @return If the app chooses to display the attachment file itself, return true
 *          If the app does not wish to handle the attachment, return false. In this case, the SDK will display the attachment using Quicklook Framework.
 *  @param fileLocation Location of the downloaded attachment file.
 *  @param parentViewController Helpshift's top view controller that can be used to present custom viewController.
 *
 * @available Version 4.10.0 or later
 */
- (BOOL) displayAttachmentFileAtLocation:(NSURL *)fileLocation onViewController:(UIViewController *)parentViewController;

@end
