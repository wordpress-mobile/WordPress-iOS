#import <Foundation/Foundation.h>

#import <Lookback/LookbackRecordingOptions.h>
#import <Lookback/LookbackRecordingSession.h>
#if TARGET_OS_IPHONE
#import <Lookback/LookbackRecordingViewController.h>
#endif

/*! @header LookbackRecorder.h
 
    @abstract
    The LookbackRecorder gives you low-level access to the UX recorder used by Participate. It records your screen and
    camera, and then uploads it to https://lookback.io for further study. Use this API to perform
    advanced Lookback features, such as diary studies or generic feedback recording.
*/

/*!
    @class LookbackRecorder 
 
    API for Lookback recording, configuration and uploading. This class can record and upload user research and feedback
    from your app. It captures the screen, front-facing camera, microphone, and tons of metadata about your app
    during the recording session.
 
    You must configure the recorder with an SDK token via +[Lookback @link setupWithAppToken: @/link] before being used.
    
    Once configured, you can:
    
    <ul>
        <li> start recording using -[LookbackRecorder @link startRecording @/link] at any time
        <li> present @link LookbackRecordingViewController @/link  to let the user do start or manage recordings
        <li> configure -[LookbackRecorder @link shakeToRecord @/link] to display a recording UI
          whenever you shake your device (if set to <code>YES</code>).
    </ul>
*/
@interface LookbackRecorder : NSObject

/*! Mandatory setup method which configures LookbackRecorder for your application.
 
    In your applicationDidFinishLaunching: or similar, call this method to prepare
    LookbackRecorder for use, using the Team Token from your integration guide at lookback.io. You can call
    this method again later to change the token.
    @param teamToken A string identifying your team, received from your team settings at http://lookback.io
*/
+ (void)setupWithAppToken:(NSString*)teamToken;

/*! Shared instance of LookbackRecorder to use from your code. You must call
    +[LookbackRecorder @link setupWithAppToken:@/link] before calling this method.
 */
+ (instancetype)sharedRecorder;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end


/*!
 Recording API.
 */
@interface LookbackRecorder (LookbackRecording)

/*! Whether LookbackRecorder is set to currently record. Setting this to YES is equivalent to calling
	-[LookbackRecorder startRecording], and setting it to NO is equivalent to calling
	[[[LookbackRecorder sharedRecorder] currentRecordingSession] stopRecording];
    
    KVO compliant √
 */
@property(nonatomic,getter=isRecording) BOOL recording;

/*! Start recording with the provided options, overriding the default options. 
 
    @note 
    The recording might not start immediately if the user hasn't accepted the privacy policy yet.
 
    @return A new recording session, configured with the given <code>options</code>.
 */
- (LookbackRecordingSession*)startRecordingWithOptions:(LookbackRecordingOptions*)options;

/*! 
 Start a recording session with the default recording options.
 
 Equivalent to:
 
    [[LookbackRecorder sharedRecorder] startRecordingWithOptions:[[LookbackRecorder sharedRecorder] options]];
 
 */
- (LookbackRecordingSession*)startRecording;

/*! Stop recording */
- (void)stopRecording;

/*! Retrieve the current recording, if one is ongoing. This is nil if recording is off. */
@property(readonly) LookbackRecordingSession *currentRecordingSession;

/*! Default recording options. These are stored in NSUserDefaults, and some can be overridden
	by the user from LookbackSettingsViewController. Changing the default options does not affect
	the current recording, if there is one. */
@property(readonly) LookbackDefaultRecordingOptions *options;

/*! Is LookbackRecorder paused? LookbackRecorder will pause automatically when showing the Recorder.
    This property doesn't do anything if LookbackRecorder is not recording (as there is nothing
	to pause).
 */
@property(nonatomic,getter=isPaused) BOOL paused;

/*! How many recordings are waiting to be previewed? This is the number shown as a red
    badge in the `LookbackRecordingViewController`. If your app does not allow access to
    the `LookbackRecordingViewController`, you should manually display this number somewhere
    in your app and allow the user to view `LookbackRecordingsTableViewController`, in order
    to finish previewing recent recordings. */
@property(readonly) NSInteger countOfRecordingsPendingPreview;

/*! How many recordings are currently uploading, or waiting to be uploaded? If your app
    does not allow access to the `LookbackRecordingViewController`, you should manually
    display this number in your app, and possibly allow the user to view
    `LookbackRecordingsTableViewController` to see the status of their uploads.

    KVO compliant √
 */
@property(readonly) NSInteger countOfRecordingsPendingUpload;

/*! If countOfRecordingsPendingUpload is > 0, this is a number between 0 and 1 for how
    far upload has progressed. */
@property(readonly) double uploadProgress;
@end

#if TARGET_OS_IPHONE

/*! Lookback user interface API. */
@interface LookbackRecorder (LookbackUI)

/*! If enabled, shows the feedback bubble when you shake the device. Tapping this bubble will
	show the LookbackRecordingViewController and let the user record. Default NO.
*/
@property(nonatomic) BOOL shakeToRecord;

/*! Whether the feedback bubble (from "shakeToRecord") is currently shown. Defaults to NO,
	but you can set it to YES immediately on app start to default to it showing, e g.
 
    KVO compliant √
*/
@property(nonatomic) BOOL feedbackBubbleVisible;


/*! The feedback bubble will pick up your navigation bar's appearance proxy's
	foreground tint color. Override it with this property.
*/
@property(nonatomic) UIColor *feedbackBubbleForegroundColor;
/*! The feedback bubble will pick up your navigation bar's appearance proxy's bar
	tint. Override it with this property.
*/
@property(nonatomic) UIColor *feedbackBubbleBackgroundColor;
/*!	You can override the icon of the feedback bubble. It will be tinted with foregroundColor. */
@property(nonatomic) UIImage *feedbackBubbleIcon;

/*! Where on the screen should the bubble appear? Use positive values as insets from top-left, or negative
    values for insets from bottom-right. */
@property(nonatomic) CGPoint feedbackBubbleInitialPosition;


/*!
	Whether the built-in LookbackRecordingViewController is currently being shown,
	either from pressing the feedback bubble or from setting this property to YES.
*/
@property(nonatomic) BOOL recorderVisible;
/*! The currently presented LookbackRecordingViewController. nil if recorderVisible is NO. */
@property(nonatomic,readonly) LookbackRecordingViewController *presentedRecorder;


/*!
	If set to YES, LookbackRecorder will show introduction dialogs if applicable at the following occasions:
	
	-  When the recorder is displayed, to solicit feedback from the user
	-  When recording starts, with instructions on how to stop recording (if recording
	   started by tapping the feedback bubble).
	-  When the feedback bubble is dismissed, with instructions on how to show it again
	
	@default YES
*/
@property(nonatomic) BOOL showIntroductionDialogs;

@end

#endif

/*! View tracing API. */
@interface LookbackRecorder (LookbackMetadata)

/*! If you are not using view controllers, or if automaticallyRecordViewControllerNames is NO,
	and you still want to track the user's location in your app, call this method whenever
	the user enters a new distinct view within your app.
    @param viewIdentifier Unique human readable identifier for a specific view
*/
- (void)enteredView:(NSString*)viewIdentifier;

/*! Like enteredView:, but for when the user exists the view.
    @see enteredView:
    @param viewIdentifier Unique human readable identifier for a specific view
*/
- (void)exitedView:(NSString*)viewIdentifier;

/*!	You might want to track events beyond user navigation; such as errors,
    user interaction milestones, network events, etc. Call this method whenever
	such an event is happening, and if a recording is taking place, the event
	will be attached to the timeline of that recording.
	
	@example <pre>
		[[LookbackRecorder_Weak lookback]
			logEvent:@"Playback Error"
			eventInfo:[NSString stringWithFormat:@"%d: %@",
				error.errorCode, error.localizedDescription]
		];
	
	@param event     The name of the event: this is the string that will show up
					 on the timeline.
	@param eventInfo Additional information about the event, for example error
	                 code, interaction variation, etc.
*/
- (void)logEvent:(NSString*)event eventInfo:(NSString*)eventInfo;
@end


/*! Debugging API. */
@interface LookbackRecorder (Debugging)
@property(nonatomic,readonly) NSString *appToken;
@end


/*! If you only want to use LookbackRecorder in builds sent to testers (e g by using the
    CocoaPods :configurations=> feature), you need to avoid both linking with
    Lookback.framework and calling any Lookback code (since that would create
    a linker error). By making all your calls to Lookback_Weak instead of
    Lookback, your calls will be disabled when not linking with Lookback, and
    you thus avoid linker errors.
 
    @example <pre>
        [LookbackRecorder_Weak setupWithAppToken:@"<MYAPPTOKEN>"];
        [LookbackRecorder_Weak sharedRecorder].shakeToRecord = YES;
        
        [[LookbackRecorder_Weak sharedRecorder] enteredView:@"Settings"];
        </pre>
*/
#define LookbackRecorder_Weak (NSClassFromString(@"LookbackRecorder"))


#pragma mark UIKit extensions

#if TARGET_OS_IPHONE
/*!
 *  Lookback-specific extenions to UIView.
 */
@interface UIView (LookbackConcealing)

/*! @discussion If set to YES, the receiver will be covered by a red rectangle in recordings
	you make with Lookback. This is useful for hiding sensitive user
    data. Secure text fields are automatically concealed when focused.
	
	@example <pre>
		- (void)viewDidLoad {
			if([LookbackRecorder_Weak sharedRecorder]) { // don't set lookback properties if lookback isn't available
				self.userEmailLabel.lookback_shouldBeConcealedInRecordings = YES;
			}
			...
		}
		</pre>
 */
@property(nonatomic) BOOL lookback_shouldBeConcealedInRecordings;

@end

/*! Implement either of these to customize the view name that is logged whenever
	the user enters your view controller during a recording. */
@interface UIViewController (LookbackViewIdentifier)
+ (NSString*)lookbackIdentifier;
- (NSString*)lookbackIdentifier;
@end

#endif

/*! Deprecated methods*/
@interface LookbackRecorder (LookbackDeprecated)

/*!
	This property has been renamed to 'recording'.
	@see setRecording:
*/
@property(nonatomic) DEPRECATED_MSG_ATTRIBUTE("Use .recording instead") BOOL enabled;
@property(nonatomic) DEPRECATED_MSG_ATTRIBUTE("Use .options.userIdentifier instead") NSString *userIdentifier;

/*! @deprecated
    Use @link sharedRecorder @/link instead. This is because Swift
	disallows the use of a static method with the same name as the class that isn't
	a constructor.
 */
+ (LookbackRecorder*)lookback;
@end
