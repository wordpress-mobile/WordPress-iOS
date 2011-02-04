#import <UIKit/UIKit.h>

// cell identifier for this custom cell
extern NSString *kCellTextField_ID;

@interface UITextFieldCell : UITableViewCell {
	IBOutlet UILabel *titleLabel;
    IBOutlet UITextField *textField;
}

+ (UITextFieldCell *) createNewTextCellFromNib;

@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UITextField *textField;

@end