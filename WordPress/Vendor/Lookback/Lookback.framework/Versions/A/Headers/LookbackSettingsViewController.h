#import <UIKit/UIKit.h>
@class Lookback, LookbackRecordingOptions;

/*! @header Lookback Settings
    Class with helpers for managing Lookback recordings.
*/

/*!
 * @class LookbackSettingsViewController
 * User interface for changing settings for how to record, and optionally for
 * starting and stopping a Lookback recording.
 *
 * @note Use LookbackRecordingViewController instead. It is more full-featured
 *       and less intrusive, and has a button to access LookbackSettingsViewController
 */
@interface LookbackSettingsViewController : UITableViewController
/*!
 *  Loads a new LookbackSettingsViewController from the .storyboard. Don't
 *  instantiate this class directly.
 *
 *  You should present the result inside a UINavigationController.
 */
+ (instancetype)settingsViewController;

/*!
 *	Allow user to customize a specific options instance before you start recording with it.
 */
+ (instancetype)settingsViewControllerForInstance:(Lookback*)lookback options:(LookbackRecordingOptions*)options;

/*!
 *  Compatibility method for old code using the less convenient method.
 *  @deprecated
 *  @param lookback Shall only be the singleton instance [Lookback @link lookback @/link].
 */
+ (instancetype)settingsViewControllerForInstance:(Lookback*)lookback;

/*!
	Whether it should be possible to start/stop recording from this view.
	Defaults to NO. You are encouraged to use LookbackRecordingViewController instead.
 */
@property(nonatomic) BOOL showsRecordButton;
@end

/*!
    If you only want to use Lookback in builds sent to testers (e g by using the
    CocoaPods :configurations=> feature), you need to avoid both linking with
    Lookback.framework and calling any Lookback code (since that would create
    a linker error). By making your calls to LookbackSettingsViewController_Weak
    instead of @link LookbackSettingsViewController @/link, your calls will be disabled when not
    linking with Lookback, and you thus avoid linker errors.

    @example <pre>
        [LookbackSettingsViewController_Weak settingsViewControllerForInstance:[Lookback lookback]];
    </pre>
*/
#define LookbackSettingsViewController_Weak (NSClassFromString(@"LookbackSettingsViewController"))


/*!
 *  Compatibility macro for old code using this view controller under its old name.
 */
#define GFSettingsViewController LookbackSettingsViewController
