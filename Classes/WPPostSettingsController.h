#import <UIKit/UIKit.h>
#import "PostDetailViewController.h"

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD					150.0

@interface WPPostSettingsController : UIViewController {
	IBOutlet UITableView *tableView;
	IBOutlet UITableViewCell *pingsTableViewCell;
	IBOutlet UITableViewCell *publishOnTableViewCell;
	IBOutlet UITableViewCell *passwordTableViewCell;
	IBOutlet UITableViewCell *passwordHintTableViewCell;
	IBOutlet UITableViewCell *resizePhotoViewCell;
	IBOutlet UITableViewCell *customFieldsCell;
	
	IBOutlet UITextField *passwordTextField;
	IBOutlet UILabel *publishOnTextField;

	IBOutlet UILabel *passwordHintLabel;

	IBOutlet UILabel *passwordLabel;
	IBOutlet UILabel *publishOnLabel;
	
	IBOutlet UISwitch *commentsSwitchControl;
	IBOutlet UISwitch *pingsSwitchControl;
	IBOutlet UISwitch *resizePhotoControl;
	IBOutlet UISwitch *customFieldsSwitchControl;
	
	IBOutlet UILabel *resizePhotoLabel;
	IBOutlet UITableViewCell *resizePhotoHintTableViewCell;
	IBOutlet UILabel *resizePhotoHintLabel;

	PostDetailViewController *postDetailViewController;	
}

@property (nonatomic, assign) PostDetailViewController * postDetailViewController;
@property (readonly) UITableView *tableView;
@property (readonly) UITextField *passwordTextField;

@property (readonly) UISwitch *commentsSwitchControl;
@property (readonly) UISwitch *pingsSwitchControl;
@property (readonly) UISwitch *customFieldsSwitchControl;

- (void)reloadData;

- (void)endEditingAction:(id)sender;
//will be called when auto save method is called.
- (void)updateValuesToCurrentPost;

@end
