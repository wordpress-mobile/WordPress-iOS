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

@interface WPcomLoginViewController : UITableViewController <UITextFieldDelegate> {
	NSString *footerText, *buttonText, *username, *password, *WPcomXMLRPCUrl;
	BOOL isAuthenticated;
}

@property (nonatomic, retain) NSString *footerText, *buttonText, *username, *password, *WPcomXMLRPCUrl;
@property (nonatomic, assign) BOOL isAuthenticated;

- (void)saveLoginData;
- (BOOL)authenticate;
- (void)clearLoginData;
- (void)selectPasswordField:(id)sender;
- (void)signIn:(id)sender;

@end
