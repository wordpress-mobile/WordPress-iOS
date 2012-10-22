//
//  EditBlogViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"
#import "UITableViewSwitchCell.h"
#import "UITableViewTextFieldCell.h"
#import "Blog.h"
#import "SettingsViewControllerDelegate.h"

@interface EditSiteViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
	IBOutlet UITableView *tableView;
	UITextField *urlTextField, *usernameTextField, *passwordTextField, *lastTextField;
    UITableViewSwitchCell *switchCell;
    UIBarButtonItem *saveButton;
    Blog *blog;
    NSArray *subsites;
	UIActivityIndicatorView *savingIndicator;
    BOOL isValidating;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSString *password, *username, *url;
@property (nonatomic, copy) NSString *startingPwd, *startingUser, *startingUrl;
@property (nonatomic, assign) BOOL geolocationEnabled;
@property (nonatomic, strong) UITableViewTextFieldCell *urlCell, *usernameCell, *passwordCell;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) UIActivityIndicatorView *savingIndicator;
@property (nonatomic, assign) BOOL isCancellable;
@property (nonatomic, weak) id<SettingsViewControllerDelegate>delegate;

@end
