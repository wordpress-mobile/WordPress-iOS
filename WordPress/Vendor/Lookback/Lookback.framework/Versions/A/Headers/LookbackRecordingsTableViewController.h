#import <UIKit/UIKit.h>

/*! @header Lookback Recordings Table
    UI for displaying the progress of uploads, and listing recent recordings.
 */

/*!
    @class LookbackRecordingsTableViewController
    @abstract See the upload status of recent recordings in a table view.
 
    The table view shows all recordings that are:
        - Pending to be reviewed. Tapping them will allow you to review them now.
        - Currently uploading recordings.
        - Recently completed uploads. Tapping them will take you to the Lookback
          web site to view the recording, if you have permissions to do so.
 
    See `-[Lookback countOfRecordingsPendingPreview]` and `-[Lookback
    countOfRecordingsPendingUpload]` for information on when you should manually
    display this view controller.
    
    You can also swipe on any recording to share its URL using a standard share sheet.
    
    The `leftBarButtonItem` is by default configured to take you to the
    `LookbackSettingsViewController`. You can set the leftBarButtonItem to nil
    to prevent your users from accessing settings.
*/
@interface LookbackRecordingsTableViewController : UITableViewController

/*! @method recordingsViewController
    @abstract The default and only constructor for this class. Do not
              use any other constructor, or its UI will not be loaded. */
+ (instancetype)recordingsViewController;
@end
