#import <UIKit/UIKit.h>
#import "Confirmable.h"

// Typedef's
typedef NS_ENUM(NSInteger, SettingsTextModes) {
    SettingsTextModesText,
    SettingsTextModesLowerCaseText,
    SettingsTextModesURL,
    SettingsTextModesEmail,
    SettingsTextModesPassword,
    SettingsTextModesNewPassword
};

typedef void (^SettingsTextAction)(void);
typedef void (^SettingsTextChanged)(NSString * _Nonnull);
typedef void (^SettingsAttributedTextChanged)(NSAttributedString * _Nonnull);
typedef void (^SettingsTextOnDismiss)(void);

/// Reusable component that renders a UITextField + Hint onscreen. Useful for Text / Password / Email data entry.
///
@interface SettingsTextViewController : UITableViewController<Confirmable>

/// Block to be executed on dismiss, if the value was effectively updated.
///
@property (nullable, nonatomic, copy) SettingsTextChanged onValueChanged;

/// Block to be executed on dismiss, if the value was effectively updated.
///
@property (nullable, nonatomic, copy) SettingsAttributedTextChanged onAttributedValueChanged;

/// Block to be executed whenever the Action, if visible, is pressed.
///
@property (nullable, nonatomic, copy) SettingsTextAction onActionPress;
/// Optional block to be executed when the viewController is dismissed.
///
@property (nullable, nonatomic, copy) SettingsTextOnDismiss onDismiss;

/// String to be displayed at the bottom.
///
@property (nullable, nonatomic, strong) NSString *hint;

/// Placeholder string to be displayed, in case the text is empty.
///
@property (nullable, nonatomic, strong) NSString *placeholder;

/// The raw attributed string (current value) to edit.
///
@property (nullable, nonatomic, strong) NSAttributedString *attributedText;

/// The raw string (current value) to edit.
///
@property (nullable, nonatomic, strong) NSString *text;

/// Specifies the Notice Message that should be displayed on top of the table.
///
@property (nullable, nonatomic, copy) NSString *notice;

/// Specifies the Action Button Text. If visible.
///
@property (nullable, nonatomic, copy) NSString *actionText;

/// Indicates whether an action button should be displayed at the bottom, or not.
///
@property (nonatomic, assign) BOOL displaysActionButton;

/// Indicates whether input should be validated or not. Defaults to YES.
///
@property (nonatomic, assign) BOOL validatesInput;

/// Textfield Autocorrection
///
@property (nonatomic, assign) UITextAutocorrectionType autocorrectionType;

/// Sets the Text Input Mode:
///
/// - SettingsTextModesText: Default mode
/// - SettingsTextModesLowerCaseText: Lower case text
/// - SettingsTextModesURL: Uses URL keyboard type, lower case text, no autocorrection
/// - SettingsTextModesEmail: Will perform Email validation before hitting the callback.
/// - SettingsTextModesPassword: Secure Text Entry is enabled.
///
@property (nonatomic, assign) SettingsTextModes mode;

/// If YES, Cancel and Save buttons will be added to the navigation bar.
///
@property (nonatomic, assign) BOOL displaysNavigationButtons;

/// Required initializer.
///
/// Parameters:
///  - text: The raw string (current value) to edit.
///  - placeholder: Placeholder string to be displayed, in case the text is empty.
///  - hint: String to be displayed at the bottom.
///
- (nonnull instancetype)initWithText:(NSString * __nullable)text
                         placeholder:(NSString * __nullable)placeholder
                                hint:(NSString * __nullable)hint;

/// Required initializer.
///
/// Parameters:
///  - text: The attributed string (current value) to edit.
///  - placeholder: Placeholder string to be displayed, in case the text is empty.
///  - hint: String to be displayed at the bottom.
///
- (nonnull instancetype)initWithAttributedText:(NSAttributedString * __nullable)text
                             defaultAttributes:(NSDictionary<NSAttributedStringKey, id> * __nullable)defaultAttributes
                                   placeholder:(NSString * __nullable)placeholder
                                          hint:(NSString * __nullable)hint;

@end
