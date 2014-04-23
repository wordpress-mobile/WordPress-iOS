// This class represents a type of UITableViewCell that contains an in-cell
// UITextField.
@interface EditableCell : UITableViewCell <UITextFieldDelegate>

// This is the text field object that is embedded in the cell.
@property(nonatomic, strong, readonly) UITextField *textField;

// This is the property name to which the text in the text field is tied. The value of
// |associatedPropertyOwner| will be updated each time the text field finishes editing.
@property(nonatomic, copy) NSString *associatedProperty;

// This is the object that has the property that |associatedProperty| describes.
@property(nonatomic, weak) NSObject *associatedPropertyOwner;

@end
