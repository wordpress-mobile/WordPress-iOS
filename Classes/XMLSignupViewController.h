//
//  XMLSignupViewController.h
//  WordPress
//
//  Created by Brad Angelcyk on 8/17/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewActivityCell.h"
#import "WPWebViewController.h"
#import "AddUsersBlogsViewController.h"
#import "Blog.h"
#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"

@interface XMLSignupViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
    WordPressAppDelegate *appDelegate;
    
    NSString *buttonText, *footerText, *blogName, *email, *username, *password, *passwordconfirm;
    
    UITableView *tableView;
    UITextField *lastTextField;
}

@property (nonatomic, retain) NSString *buttonText, *footerText, *blogName, *email, *username, *password, *passwordconfirm;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) UITextField *lastTextField;

@end
