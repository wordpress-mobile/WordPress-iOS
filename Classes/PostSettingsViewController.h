#import <UIKit/UIKit.h>
#import "EditPostViewController.h"
#import "PostSettingsHelpViewController.h"
#import "CPopoverManager.h"

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD                    150.0

@class EditPostViewController;
@interface PostSettingsViewController : UIViewController {
    IBOutlet UITableView *tableView;
    IBOutlet UITableViewCell *pingsTableViewCell;
    IBOutlet UITableViewCell *publishOnTableViewCell;
    IBOutlet UITableViewCell *passwordTableViewCell;
    IBOutlet UITableViewCell *passwordHintTableViewCell;
    IBOutlet UITextField *passwordTextField;
    IBOutlet UILabel *publishOnTextField;
    IBOutlet UILabel *passwordLabel;
    IBOutlet UILabel *publishOnLabel;
    IBOutlet UISwitch *commentsSwitchControl;
    IBOutlet UISwitch *pingsSwitchControl;
    IBOutlet UISwitch *customFieldsSwitchControl;
	IBOutlet UIPopoverController *datePopover;
    EditPostViewController *postDetailViewController;
}

@property (nonatomic, assign) EditPostViewController *postDetailViewController;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UITextField *passwordTextField;
@property (nonatomic, retain) UILabel *publishOnTextField;
@property (nonatomic, retain) UISwitch *commentsSwitchControl, *pingsSwitchControl;
@property (nonatomic, retain) IBOutlet UIPopoverController *datePopover;

- (void)reloadData;
- (void)endEditingAction:(id)sender;
- (void)updateValuesToCurrentPost;
- (void)setupHelpButton;
- (IBAction)helpButtonClicked:(id)sender;

@end
