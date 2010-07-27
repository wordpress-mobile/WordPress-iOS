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

@interface EditSiteViewController : UITableViewController<UITextFieldDelegate> {
	WordPressAppDelegate *appDelegate;
	WPProgressHUD *spinner;
	//AddUsersBlogsViewController *addUsersBlogsView;
	UITextField *activeTextField;
	NSString *footerText, *addButtonText, *url, *xmlrpc, *username, *password, *blogID, *blogName, *host;
	NSArray *subsites;
	BOOL isAuthenticating, isAuthenticated, isSaving, hasSubsites, hasValidXMLRPCurl, viewDidMove, keyboardIsVisible, isWPcom;
	int blogIndex;
}

@property (nonatomic, retain) WPProgressHUD *spinner;
//@property (nonatomic, retain) AddUsersBlogsViewController *addUsersBlogsView;
@property (nonatomic, retain) UITextField *activeTextField;
@property (nonatomic, retain) NSString *footerText, *addButtonText, *url, *xmlrpc, *username, *password, *blogID, *blogName, *host;
@property (nonatomic, retain) NSArray *subsites;
@property (nonatomic, assign) BOOL isAuthenticating, isAuthenticated, isSaving, hasSubsites, hasValidXMLRPCurl, viewDidMove, keyboardIsVisible, isWPcom;
@property (nonatomic, assign) int blogIndex;

- (void)getSubsites;
- (void)authenticate;
- (void)didAuthenticateSuccessfully;
- (void)saveSite;
- (void)saveSiteInBackground;
- (void)didSaveSiteSuccessfully;
- (void)saveSiteFailed;
- (void)refreshTable;
- (void)getXMLRPCurl;
- (void)setXMLRPCUrl:(NSString *)xmlrpcUrl;
- (BOOL)blogExists;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)urlDidChange;
- (void)loadSiteData;

@end
