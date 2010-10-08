//
//  WPcomLoginViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import <UIKit/UIKit.h>
#import "WPDataController.h"
#import "AddUsersBlogsViewController.h"
#import "UITableViewActivityCell.h"
#import "WordPressAppDelegate.h"

@interface WPcomLoginViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate> {
	NSString *footerText, *buttonText, *username, *password, *WPcomXMLRPCUrl;
	BOOL isAuthenticated, isSigningIn;
	IBOutlet UITableView *tableView;
	WordPressAppDelegate *appDelegate;
}

@property (nonatomic, retain) NSString *footerText, *buttonText, *username, *password, *WPcomXMLRPCUrl;
@property (nonatomic, assign) BOOL isAuthenticated, isSigningIn;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) WordPressAppDelegate *appDelegate;

- (void)saveLoginData;
- (BOOL)authenticate;
- (void)clearLoginData;
- (void)selectPasswordField:(id)sender;
- (void)signIn:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)refreshTable;

@end
