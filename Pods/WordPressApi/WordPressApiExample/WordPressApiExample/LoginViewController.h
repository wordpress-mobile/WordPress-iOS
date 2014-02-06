//
//  LoginViewController.h
//  WordPressApiExample
//
//  Created by Jorge Bernal on 1/17/12.
//  Copyright (c) 2012 Automattic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UITableViewController<UITextFieldDelegate>
@property (nonatomic, retain) IBOutlet UITextField *urlField;
@property (nonatomic, retain) IBOutlet UITextField *usernameField;
@property (nonatomic, retain) IBOutlet UITextField *passwordField;
@end
