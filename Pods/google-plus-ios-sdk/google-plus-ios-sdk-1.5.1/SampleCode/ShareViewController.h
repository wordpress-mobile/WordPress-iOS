//
//  ShareViewController.h
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

@interface ShareViewController : UITableViewController <UITextViewDelegate>

// Attempts to share to the signed-in user's stream using the configuration from
// this view controller.
@property(weak, nonatomic) IBOutlet UIButton *shareButton;
// A label to display the result of the share action.
@property(weak, nonatomic) IBOutlet UILabel *shareStatus;
// A label to signify the native sharebox switch (or to indicate that the user needs to sign in).
@property(weak, nonatomic) IBOutlet UILabel *nativeShareboxLabel;
// A toggle switch to determine whether or not to share using the native sharebox.
@property(weak, nonatomic) IBOutlet UISwitch *useNativeSharebox;

// Called when the share button is pressed.
- (IBAction)shareButton:(id)sender;

// Called when native sharebox switch is toggled.
- (IBAction)toggleUseNativeSharebox:(UISwitch *)sender;

@end
