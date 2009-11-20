//
//  BlogHTTPAuthenticationViewController.h
//  WordPress
//
//  Created by Jeff Stieler on 11/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EditBlogViewController;

@interface BlogHTTPAuthenticationViewController : UIViewController {
	IBOutlet UITableView *blogHTTPAuthTable;
	
	IBOutlet UITableViewCell *blogHTTPAuthEnabledTabelCell;
	IBOutlet UITableViewCell *blogHTTPAuthUsernameTabelCell;
	IBOutlet UITableViewCell *blogHTTPAuthPasswordTabelCell;
	
	IBOutlet UISwitch *blogHTTPAuthEnabled;
	IBOutlet UITextField *blogHTTPAuthUsername;
	IBOutlet UITextField *blogHTTPAuthPassword;
	
	BOOL authEnabled, firstView;
	NSString *authUsername;
	NSString *authPassword;
	
	IBOutlet EditBlogViewController *editBlogViewController;
}

@property (readonly)UISwitch *blogHTTPAuthEnabled;
@property (readonly)UITextField *blogHTTPAuthUsername;
@property (readonly)UITextField *blogHTTPAuthPassword;
@property (readwrite, assign)EditBlogViewController *editBlogViewController;
@property (readwrite, assign)BOOL authEnabled, firstView;
@property (readwrite, retain)NSString *authUsername, *authPassword;

@end
