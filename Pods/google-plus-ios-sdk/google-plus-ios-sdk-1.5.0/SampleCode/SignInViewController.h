//
//  SignInViewController.h
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

@class GPPSignInButton;

// A view controller for the Google+ sign-in button which initiates a standard
// OAuth 2.0 flow and provides an access token and a refresh token. A "Sign out"
// button is provided to allow users to sign out of this application.
@interface SignInViewController : UITableViewController<UIAlertViewDelegate>

@property(weak, nonatomic) IBOutlet GPPSignInButton *signInButton;
// A label to display the result of the sign-in action.
@property(weak, nonatomic) IBOutlet UILabel *signInAuthStatus;
// A label to display the signed-in user's display name.
@property(weak, nonatomic) IBOutlet UILabel *userName;
// A label to display the signed-in user's email address.
@property(weak, nonatomic) IBOutlet UILabel *userEmailAddress;
// An image view to display the signed-in user's avatar image.
@property(weak, nonatomic) IBOutlet UIImageView *userAvatar;
// A button to sign out of this application.
@property(weak, nonatomic) IBOutlet UIButton *signOutButton;
// A button to disconnect user from this application.
@property(weak, nonatomic) IBOutlet UIButton *disconnectButton;
// A button to inspect the authorization object.
@property(weak, nonatomic) IBOutlet UIButton *credentialsButton;
// A dynamically-created slider for controlling the sign-in button width.
@property(weak, nonatomic) UISlider *signInButtonWidthSlider;

// Called when the user presses the "Sign out" button.
- (IBAction)signOut:(id)sender;
// Called when the user presses the "Disconnect" button.
- (IBAction)disconnect:(id)sender;
// Called when the user presses the "Credentials" button.
- (IBAction)showAuthInspector:(id)sender;

@end
