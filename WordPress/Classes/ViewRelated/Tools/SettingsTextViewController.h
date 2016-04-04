#import <UIKit/UIKit.h>


typedef void (^SettingsTextChanged)(NSString *);

// Reusable component that renders a UITextField + Hint onscreen. Useful for Text / Password / Email data entry.
//
@interface SettingsTextViewController : UITableViewController

// Block to be executed on dismiss, if the value was effectively updated.
//
@property (nonatomic, copy) SettingsTextChanged onValueChanged;

// Property to indicate whether email validation should be performed, or not.
//
@property (nonatomic, assign) BOOL isEmail;

// Indicates whether secure text entry is requried, or not.
//
@property (nonatomic, assign) BOOL isPassword;

// Required initializer.
//
// Parameters:
//  - text: The raw string (current value) to edit.
//  - placeholder: Placeholder string to be displayed, in case the text is empty.
//  - hint: String to be displayed at the bottom.
//
- (instancetype)initWithText:(NSString *)text placeholder:(NSString *)placeholder hint:(NSString *)hint;

@end
