//
//  JetpackSettingsViewController.h
//  WordPress
//
//  Created by Eric Johnson on 8/24/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JetpackAuthUtil.h"
#import "UITableViewActivityCell.h"
#import "UITableViewTextFieldCell.h"
#import "SettingsViewControllerDelegate.h"

#define kNeedJetpackLogIn NSLocalizedString(@"To access stats, enter the WordPress.com login used with the Jetpack plugin.", @"");

@class Blog;

@interface JetpackSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate> {
    IBOutlet UITableView *tableView;
    Blog *blog;
    UITextField *usernameTextField;
    UITextField *passwordTextField;
    UITextField *lastTextField;
    UITableViewActivityCell *verifyCredentialsActivityCell;
    UITableViewTextFieldCell *usernameCell;
    UITableViewTextFieldCell *passwordCell;
    BOOL isTesting;
    BOOL isTestSuccessful;
    JetpackAuthUtil *jetpackAuthUtils;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, weak) id<SettingsViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isCancellable;

@end
