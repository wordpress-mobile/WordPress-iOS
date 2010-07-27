//
//  AddSiteViewController.h
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

@interface AddSiteViewController : UITableViewController<UITextFieldDelegate> {
	WordPressAppDelegate *appDelegate;
	WPProgressHUD *spinner;
	AddUsersBlogsViewController *addUsersBlogsView;
	UITextField *activeTextField;
	NSString *footerText, *addButtonText, *url, *xmlrpc, *username, *password, *blogID, *blogName, *host;
	NSArray *subsites;
	BOOL isAuthenticating, isAuthenticated, isAdding, hasSubsites, hasValidXMLRPCurl, viewDidMove, keyboardIsVisible;
}

@property (nonatomic, retain) WPProgressHUD *spinner;
@property (nonatomic, retain) AddUsersBlogsViewController *addUsersBlogsView;
@property (nonatomic, retain) UITextField *activeTextField;
@property (nonatomic, retain) NSString *footerText, *addButtonText, *url, *xmlrpc, *username, *password, *blogID, *blogName, *host;
@property (nonatomic, retain) NSArray *subsites;
@property (nonatomic, assign) BOOL isAuthenticating, isAuthenticated, isAdding, hasSubsites, hasValidXMLRPCurl, viewDidMove, keyboardIsVisible;

- (void)getSubsites;
- (void)authenticate;
- (void)didAuthenticateSuccessfully;
- (void)addSite;
- (void)addSiteInBackground;
- (void)didAddSiteSuccessfully;
- (void)addSiteFailed;
- (void)refreshTable;
- (void)getXMLRPCurl;
- (void)setXMLRPCUrl:(NSString *)xmlrpcUrl;
- (BOOL)blogExists;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)urlDidChange;

@end
