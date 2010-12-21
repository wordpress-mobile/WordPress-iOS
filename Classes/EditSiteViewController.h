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
#import "BlogDataManager.h"
#import "AddUsersBlogsViewController.h"
#import "BlogSettingsViewController.h"
#import "Blog.h";

@interface EditSiteViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate> {
	WordPressAppDelegate *appDelegate;
	WPProgressHUD *spinner;
	//AddUsersBlogsViewController *addUsersBlogsView;
	IBOutlet UITableView *tableView;
	UITextField *activeTextField;
	NSString *footerText, *addButtonText, *password;
	NSArray *subsites;
	BOOL isAuthenticating, isAuthenticated, isSaving, hasSubsites, hasValidXMLRPCurl, viewDidMove, keyboardIsVisible;
	int blogIndex;
    Blog *blog;
}

@property (nonatomic, retain) WPProgressHUD *spinner;
//@property (nonatomic, retain) AddUsersBlogsViewController *addUsersBlogsView;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) UITextField *activeTextField;
@property (nonatomic, retain) NSString *footerText, *addButtonText, *password;
@property (nonatomic, retain) NSArray *subsites;
@property (nonatomic, assign) BOOL isAuthenticating, isAuthenticated, isSaving, hasSubsites, hasValidXMLRPCurl, viewDidMove, keyboardIsVisible;
@property (nonatomic, assign) int blogIndex;
@property (nonatomic, retain) Blog *blog;

- (void)authenticate;
- (void)saveSite;
- (void)saveSiteInBackground;
- (void)didSaveSiteSuccessfully;
- (void)saveSiteFailed;
- (void)refreshTable;
- (void)getXMLRPCurl;
- (void)setXMLRPCUrl:(NSString *)xmlrpcUrl;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)urlDidChange;
- (IBAction)cancel:(id)sender;

@end
