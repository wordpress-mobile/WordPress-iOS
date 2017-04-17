#import <Foundation/Foundation.h>
#import <Lookback/LookbackDeprecated.h>
#import <Lookback/LookbackRecordingOptions.h>
#import <Lookback/LookbackRecordingSession.h>
#if TARGET_OS_IPHONE
#import <Lookback/LookbackSettingsViewController.h>
#import <Lookback/LookbackRecordingViewController.h>
#import <Lookback/LookbackRecordingsTableViewController.h>
#endif

/*! @header Lookback.h
 
    @abstract
    Public interface for Lookback, the UX testing tool that records your screen
    and camera and uploads it to http://lookback.io for further study.
*/

/*!
    API for Lookback recording & configuration.
 
    Must be configured with an app token via +[Lookback @link setupWithAppToken: @/link] before being used.
    Once configured, you can:
 
	- start recording using -[Lookback @link startRecording @/link] at any time
 
	- present @link LookbackRecordingViewController @/link  to let the user do start or manage recordings
 
    - configure -[Lookback @link shakeToRecord @/link] to display a recording UI
	  whenever you shake your device (if set to <code>YES</code>).
*/
@interface Lookback : NSObject

/*! Mandatory setup method which configures Lookback for your application.
 
    In your applicationDidFinishLaunching: or similar, call this method to prepare
    Lookback for use, using the Team Token from your integration guide at lookback.io. You can call
    this method again later to change the token.
    @param teamToken A string identifying your team, received from your team settings at http://lookback.io
*/
+ (void)setupWithAppToken:(NSString*)teamToken;

/*! Shared instance of Lookback to use from your code. You must call
    +[Lookback @link setupWithAppToken:@/link] before calling this method.
 */
+ (instancetype)sharedLookback;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end


/*!
 Recording API.
 */
@interface Lookback (LookbackRecording)

/*! Whether Lookback is set to currently record. Setting this to YES is equivalent to calling
	-[Lookback startRecording], and setting it to NO is equivalent to calling
	[[[Lookback sharedLookback] currentRecordingSession] stopRecording];
    
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
 
    [[Lookback sharedLookback] startRecordingWithOptions:[[Lookback sharedLookback] options]];
 
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

/*! Is Lookback paused? Lookback will pause automatically when showing the Recorder.
    This property doesn't do anything if Lookback is not recording (as there is nothing
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
@interface Lookback (LookbackUI)

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
	If set to YES, Lookback will show introduction dialogs if applicable at the following occasions:
	
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
@interface Lookback (LookbackMetadata)

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
		[[Lookback_Weak lookback]
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
@interface Lookback (Debugging)
@property(nonatomic,readonly) NSString *appToken;
@end


/*! If you only want to use Lookback in builds sent to testers (e g by using the
    CocoaPods :configurations=> feature), you need to avoid both linking with
    Lookback.framework and calling any Lookback code (since that would create
    a linker error). By making all your calls to Lookback_Weak instead of
    Lookback, your calls will be disabled when not linking with Lookback, and
    you thus avoid linker errors.
 
    @example <pre>
        [Lookback_Weak setupWithAppToken:@"<MYAPPTOKEN>"];
        [Lookback_Weak sharedLookback].shakeToRecord = YES;
        
        [[Lookback_Weak sharedLookback] enteredView:@"Settings"];
        </pre>
*/
#define Lookback_Weak (NSClassFromString(@"Lookback"))


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
			if([Lookback_Weak lookback]) { // don't set lookback properties if lookback isn't available
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
@interface Lookback (LookbackDeprecated)

/*!
	This property has been renamed to 'recording'.
	@see setRecording:
*/
@property(nonatomic) DEPRECATED_MSG_ATTRIBUTE("Use .recording instead") BOOL enabled;
@property(nonatomic) DEPRECATED_MSG_ATTRIBUTE("Use .options.userIdentifier instead") NSString *userIdentifier;

/*! @deprecated
    Use @link sharedLookback @/link instead. This is because Swift
	disallows the use of a static method with the same name as the class that isn't
	a constructor.
 */
+ (Lookback*)lookback;
@end
