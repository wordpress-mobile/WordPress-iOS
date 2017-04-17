#import <UIKit/UIKit.h>

/*! @header Lookback Recording
    Class with helpers for starting and stopping recording.
*/


/*!
	Simple UI to start/stop recording, access settings and list experiences.
	Displayed on top of your app as a separate UIWindow.
*/
@interface LookbackRecordingViewController : UIViewController
/*!
 * Creates a window on top of the app and displays this view controller.
 * @param animated Whether to present the vc with an animation.
*/
+ (instancetype)presentOntoScreenAnimated:(BOOL)animated;

/*!
 * Destroys the overlay window and removes the receives from the screen.
 * @param animated Whether to do so in an animated fashion.
 */
- (void)dismissAnimated:(BOOL)animated;
@end

/*! Sent when the recorder is displayed on screen. */
static NSString *const LookbackRecordingVCWasPresentedNotification = @"io.lookback.recorder.presented";

/*! Sent when the recorder is no longer on screen. */
static NSString *const LookbackRecordingVCWasDismissedNotification = @"io.lookback.recorder.dismissed";
