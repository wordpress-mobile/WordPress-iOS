//
//  AddSiteViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/23/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h";
#import "WPDataController.h";
#import "WPProgressHUD.h"
#import "BlogDataManager.h"

@interface AddSiteViewController : UITableViewController<UITextFieldDelegate> {
	WordPressAppDelegate *appDelegate;
	WPProgressHUD *spinner;
	NSString *footerText, *addButtonText, *url, *xmlrpc, *username, *password, *blogID, *blogName, *host;
	NSArray *subsites;
	BOOL isAuthenticating, isAuthenticated, isAdding, hasSubsites, hasValidXMLRPCurl;
}

@property (nonatomic, retain) WordPressAppDelegate *appDelegate;
@property (nonatomic, retain) WPProgressHUD *spinner;
@property (nonatomic, retain) NSString *footerText, *addButtonText, *url, *xmlrpc, *username, *password, *blogID, *blogName, *host;
@property (nonatomic, assign) BOOL isAuthenticating, isAuthenticated, isAdding, hasSubsites, hasValidXMLRPCurl;

- (void)getSubsites;
- (void)didGetSubsitesSuccessfully;
- (void)authenticate;
- (void)didAuthenticateSuccessfully;
- (void)addSite;
- (void)addSiteInBackground;
- (void)didAddSiteSuccessfully;
- (void)refreshTable;
- (void)getXMLRPCurl;
- (void)setXMLRPCUrl:(NSString *)xmlrpcUrl;

@end
