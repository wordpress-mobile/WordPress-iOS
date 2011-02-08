//
//  AddSiteViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h";
#import "UIDevice-Hardware.h"
#import "WPDataController.h";
#import "WPProgressHUD.h"
#import "BlogDataManager.h"
#import "AddUsersBlogsViewController.h"
#import "Blog.h";
#import "TouchXML.h"

@interface AddSiteViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate> {
	WordPressAppDelegate *appDelegate;
	WPProgressHUD *spinner;
	AddUsersBlogsViewController *addUsersBlogsView;
	IBOutlet UITableView *tableView;
	UITextField *activeTextField, *urlTextField;
	NSString *footerText, *addButtonText, *url, *xmlrpc, *username, *password, *host, *blogName;
    NSNumber *blogID;
	NSArray *subsites;
	BOOL isAuthenticating, isAuthenticated, isGettingXMLRPCURL, isAdding, hasSubsites, hasValidXMLRPCurl, viewDidMove, keyboardIsVisible, hasCheckedForSubsites;
}

@property (nonatomic, retain) WPProgressHUD *spinner;
@property (nonatomic, retain) AddUsersBlogsViewController *addUsersBlogsView;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) UITextField *activeTextField;
@property (nonatomic, retain) NSString *footerText, *addButtonText, *url, *xmlrpc, *username, *password, *host, *blogName;
@property (nonatomic, retain) NSNumber *blogID;
@property (nonatomic, retain) NSArray *subsites;
@property (nonatomic, assign) BOOL isAuthenticating, isAuthenticated, isAdding, hasSubsites, hasValidXMLRPCurl, viewDidMove, keyboardIsVisible, hasCheckedForSubsites;

@end
