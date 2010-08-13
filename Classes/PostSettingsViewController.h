#import <UIKit/UIKit.h>
#import "PostViewController.h"
#import "PostSettingsHelpViewController.h"

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD                    150.0

@interface PostSettingsViewController : UIViewController {
    IBOutlet UITableView *tableView;
    IBOutlet UITableViewCell *pingsTableViewCell;
    IBOutlet UITableViewCell *publishOnTableViewCell;
    IBOutlet UITableViewCell *passwordTableViewCell;
    IBOutlet UITableViewCell *passwordHintTableViewCell;
    IBOutlet UITableViewCell *resizePhotoViewCell;
    IBOutlet UITextField *passwordTextField;
    IBOutlet UILabel *publishOnTextField;
    IBOutlet UILabel *passwordLabel;
    IBOutlet UILabel *publishOnLabel;
    IBOutlet UISwitch *commentsSwitchControl;
    IBOutlet UISwitch *pingsSwitchControl;
    IBOutlet UISwitch *resizePhotoControl;
    IBOutlet UISwitch *customFieldsSwitchControl;
    IBOutlet UILabel *resizePhotoLabel;
    IBOutlet UITableViewCell *resizePhotoHintTableViewCell;
    PostViewController *postDetailViewController;
}

@property (nonatomic, assign) PostViewController *postDetailViewController;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UITextField *passwordTextField;
@property (nonatomic, retain) UILabel *publishOnTextField;
@property (nonatomic, retain) UISwitch *commentsSwitchControl, *pingsSwitchControl, *resizePhotoControl;

- (void)reloadData;
- (void)endEditingAction:(id)sender;
- (void)updateValuesToCurrentPost;
- (void)setupHelpButton;
- (IBAction)helpButtonClicked:(id)sender;

@end
