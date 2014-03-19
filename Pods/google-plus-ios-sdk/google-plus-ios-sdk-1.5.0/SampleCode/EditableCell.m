#import "EditableCell.h"

// If we don't assign the text label any text, then it won't be given a frame.
// We give it an invisible string so that we can copy its frame to the text
// field without obscuring the text.
static NSString * const kBlankLabelString = @" ";

@implementation EditableCell

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

  if (self) {
    self.textLabel.text = kBlankLabelString;

    _textField = [[UITextField alloc] init];
    _textField.delegate = self;
    _textField.adjustsFontSizeToFitWidth = YES;
    _textField.minimumFontSize = 0;
    _textField.textAlignment = UITextAlignmentLeft;
    _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    [self.contentView addSubview:_textField];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  // If the textLabel just has the placeholder blank text, then
  // don't bother positioning the text field around it.
  if ([self.textLabel.text isEqualToString:kBlankLabelString]) {
    self.textField.frame = self.textLabel.frame;
    return;
  }

  // Now that we know the cell has a non-empty label, we should
  // position the text field to the right of the label.
  CGFloat labelWidth =
      [self.textLabel.text sizeWithFont:self.textLabel.font].width;
  const CGFloat kPadding = 20.0f;
  CGRect labelFrame = self.textLabel.frame;

  self.textField.frame = CGRectMake(labelFrame.origin.x + labelWidth + kPadding,
                                    labelFrame.origin.y,
                                    labelFrame.size.width - labelWidth - kPadding,
                                    labelFrame.size.height);
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self.textField resignFirstResponder];
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  [self.associatedPropertyOwner setValue:textField.text forKey:self.associatedProperty];
}

@end
