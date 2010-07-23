//
//  ;;
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPDataController.h"
#import "AddUsersBlogsViewController.h"

@interface WPcomLoginViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate> {
	NSString *footerText, *buttonText, *username, *password, *WPcomXMLRPCUrl;
	BOOL isAuthenticated, isSigningIn;
	IBOutlet UITableView *tableView;
}

@property (nonatomic, retain) NSString *footerText, *buttonText, *username, *password, *WPcomXMLRPCUrl;
@property (nonatomic, assign) BOOL isAuthenticated, isSigningIn;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

- (void)saveLoginData;
- (BOOL)authenticate;
- (void)clearLoginData;
- (void)selectPasswordField:(id)sender;
- (void)signIn:(id)sender;
- (IBAction)cancel:(id)sender;

@end
