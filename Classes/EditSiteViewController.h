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

@protocol EditSiteViewControllerDelegate;

@interface EditSiteViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, NSXMLParserDelegate> {
	IBOutlet UITableView *tableView;
	UITextField *urlTextField, *usernameTextField, *passwordTextField, *jpUsernameTextField, *jpPasswordTextField, *lastTextField;
    UITableViewSwitchCell *switchCell;
    UIBarButtonItem *saveButton;
	BOOL isValidating;
    Blog *blog;
    NSArray *subsites;
	UIActivityIndicatorView *savingIndicator;
    BOOL isDotOrg, isTestingJetpack;
    NSMutableString *currentNode;
    NSMutableDictionary *parsedBlog;
    BOOL foundMatchingBlogInAPI;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSString *password, *username, *jpPassword, *jpUsername, *url;
@property (nonatomic, assign) BOOL geolocationEnabled;
@property (nonatomic, retain) UITableViewTextFieldCell *urlCell, *usernameCell, *passwordCell, *jpUsernameCell, *jpPasswordCell;
@property (nonatomic, retain) Blog *blog;
@property (nonatomic, retain) UIActivityIndicatorView *savingIndicator;
@property (nonatomic) BOOL isDotOrg;
@property (nonatomic, retain) NSString *footerText, *buttonText;
@property (nonatomic, retain) NSMutableString *currentNode;
@property (nonatomic, retain) NSMutableDictionary *parsedBlog;
@property (assign) id<EditSiteViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isStatsInitiated;
@property (nonatomic, assign) BOOL isCancellable;

@end

@protocol EditSiteViewControllerDelegate <NSObject>
- (void)controllerDidDismiss:(EditSiteViewController *)controller;
@end