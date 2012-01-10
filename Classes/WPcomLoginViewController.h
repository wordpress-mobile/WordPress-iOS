//
//  WPcomLoginViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import <UIKit/UIKit.h>
#import "AddUsersBlogsViewController.h"
#import "UITableViewActivityCell.h"
#import "WordPressAppDelegate.h"

@interface WPcomLoginViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate> {
	NSString *footerText, *buttonText, *username, *password, *WPcomXMLRPCUrl;
	BOOL isAuthenticated, isSigningIn, isStatsInitiated;
	IBOutlet UITableView *tableView;
	WordPressAppDelegate *appDelegate;
}

@property (nonatomic, retain) NSString *footerText, *buttonText, *username, *password, *WPcomXMLRPCUrl;
@property (nonatomic, assign) BOOL isAuthenticated, isSigningIn, isStatsInitiated;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) WordPressAppDelegate *appDelegate;

- (IBAction)cancel:(id)sender;
@end
