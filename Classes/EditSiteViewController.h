//
//  EditBlogViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h";
#import "WPDataController.h";
#import "WPProgressHUD.h"
#import "AddUsersBlogsViewController.h"
#import "UITableViewSwitchCell.h"
#import "Blog.h";

@interface EditSiteViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
	IBOutlet UITableView *tableView;
	UITextField *urlTextField, *usernameTextField, *passwordTextField;
    UITableViewSwitchCell *switchCell;
    UIBarButtonItem *doneButton;
	BOOL isValidating;
    Blog *blog;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSString *password, *username, *url;
@property (nonatomic, retain) UITableViewCell *urlCell, *usernameCell, *passwordCell;
@property (nonatomic, retain) Blog *blog;

@end
