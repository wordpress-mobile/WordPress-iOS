//
//  EditableCell.m
//
//  Copyright 2013 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "EditableCell.h"

#import "Availability.h"

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
  CGFloat labelWidth = 0.f;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
  if ([self.textLabel.text respondsToSelector:@selector(sizeWithAttributes:)]) {
    NSDictionary *attributes = @{ NSFontAttributeName : self.textLabel.font };
    labelWidth = [self.textLabel.text sizeWithAttributes:attributes].width;
  } else {
    // Using the deprecated method as this instance doesn't respond to the new method since this is
    // running on an older OS version.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    labelWidth = [self.textLabel.text sizeWithFont:self.textLabel.font].width;
#pragma clang diagnostic pop
  }
#else
  labelWidth = [self.textLabel.text sizeWithFont:self.textLabel.font].width;
#endif
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
