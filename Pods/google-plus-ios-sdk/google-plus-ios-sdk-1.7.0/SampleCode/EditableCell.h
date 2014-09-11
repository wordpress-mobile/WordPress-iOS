//
//  EditableCell.h
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
