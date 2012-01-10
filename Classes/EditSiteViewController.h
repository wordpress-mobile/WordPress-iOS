//
//  EditBlogViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"
#import "AddUsersBlogsViewController.h"
#import "UITableViewSwitchCell.h"
#import "UITableViewTextFieldCell.h"
#import "Blog.h"
#import "HelpViewController.h"
#import "WPWebViewController.h"

@interface EditSiteViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
	IBOutlet UITableView *tableView;
	UITextField *urlTextField, *usernameTextField, *passwordTextField;
    UITableViewSwitchCell *switchCell;
    UIBarButtonItem *saveButton;
	BOOL isValidating;
    Blog *blog;
    NSArray *subsites;
	UIActivityIndicatorView *savingIndicator;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSString *password, *username, *url;
@property (nonatomic, assign) BOOL geolocationEnabled;
@property (nonatomic, retain) UITableViewTextFieldCell *urlCell, *usernameCell, *passwordCell;
@property (nonatomic, retain) Blog *blog;
@property (nonatomic, retain) UIActivityIndicatorView *savingIndicator;

@end
