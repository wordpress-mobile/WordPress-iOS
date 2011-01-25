#import <UIKit/UIKit.h>
#import "EditPostViewController.h"
#import "PostSettingsHelpViewController.h"
#import "CPopoverManager.h"

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD                    150.0

@class EditPostViewController;
@interface PostSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource> {
    IBOutlet UITableView *tableView;
    IBOutlet UITableViewCell *statusTableViewCell;
    IBOutlet UITableViewCell *visibilityTableViewCell;
    IBOutlet UITableViewCell *publishOnTableViewCell;
    IBOutlet UILabel *statusLabel;
    IBOutlet UILabel *visibilityLabel;
    IBOutlet UITextField *passwordTextField;
    IBOutlet UILabel *publishOnLabel;
    IBOutlet UILabel *publishOnDateLabel;
    EditPostViewController *postDetailViewController;
    NSArray *statusList;
    NSArray *visibilityList;
    UIPickerView *pickerView;
    UIToolbar *accesoryToolbar;
    UIDatePicker *datePickerView;
    BOOL isShowingPicker, isShowingDatePicker, isShowingKeyboard;
}

@property (nonatomic, assign) EditPostViewController *postDetailViewController;

- (void)reloadData;
- (void)endEditingAction:(id)sender;

@end
