//
//  MomentsViewController.h
//
//  Copyright 2012 Google Inc.
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

#import <UIKit/UIKit.h>

// A view controller for writing different kinds of moments to Google+.
// The open-source GTLPlus libraries are required. For more details, see
// https://developers.google.com/+/features/app-activities .
@interface MomentsViewController : UIViewController<
    UITableViewDelegate,
    UITableViewDataSource,
    UITextFieldDelegate> {
  BOOL keyboardVisible_;
}

// A label to prompt the selection of a moment.
@property (retain, nonatomic) IBOutlet UILabel *selectionLabel;
// The table that displays the different kinds of moments available.
@property (retain, nonatomic) IBOutlet UITableView *momentsTable;
// The view for the bootom controls.
@property (retain, nonatomic) IBOutlet UIView *bottomControls;
// The target URL to associate with this moment.
@property (retain, nonatomic) IBOutlet UITextField *momentURL;
// A label to display the result of writing a moment.
@property (retain, nonatomic) IBOutlet UILabel *momentStatus;
// The "Add Moment" button.
@property (retain, nonatomic) IBOutlet UIButton *addButton;

// Called when the user presses the "Add Moment" button.
- (IBAction)momentButton:(id)sender;

@end
