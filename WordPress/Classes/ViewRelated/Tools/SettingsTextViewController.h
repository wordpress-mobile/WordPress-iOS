#import <UIKit/UIKit.h>


// Typedef's
typedef NS_ENUM(NSInteger, SettingsTextModes) {
    SettingsTextModesText,
    SettingsTextModesEmail,
    SettingsTextModesPassword
};

typedef void (^SettingsTextChanged)(NSString *);

/// Reusable component that renders a UITextField + Hint onscreen. Useful for Text / Password / Email data entry.
///
@interface SettingsTextViewController : UITableViewController

/// Block to be executed on dismiss, if the value was effectively updated.
///
@property (nonatomic, copy) SettingsTextChanged onValueChanged;

/// Sets the Text Input Mode:
///
/// - SettingsTextModesText: Default mode
/// - SettingsTextModesEmail: Will perform Email validation before hitting the callback.
/// - SettingsTextModesPassword: Secure Text Entry is enabled.
///
@property (nonatomic, assign) SettingsTextModes mode;

/// Required initializer.
///
/// Parameters:
///  - text: The raw string (current value) to edit.
///  - placeholder: Placeholder string to be displayed, in case the text is empty.
///  - hint: String to be displayed at the bottom.
///
- (instancetype)initWithText:(NSString *)text placeholder:(NSString *)placeholder hint:(NSString *)hint;

@end
