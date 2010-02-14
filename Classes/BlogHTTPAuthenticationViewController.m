//
//  BlogHTTPAuthenticationViewController.m
//  WordPress
//
//  Created by Jeff Stieler on 11/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BlogHTTPAuthenticationViewController.h"
#import "BlogDataManager.h"

@implementation BlogHTTPAuthenticationViewController

@synthesize blogHTTPAuthEnabled, blogHTTPAuthUsername, blogHTTPAuthPassword, editBlogViewController, authEnabled, authUsername, authPassword, firstView;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0) {
		return blogHTTPAuthEnabledTabelCell;
	} else if (indexPath.row == 1) {
		return blogHTTPAuthUsernameTabelCell;
	} else if (indexPath.row == 2) {
		return blogHTTPAuthPasswordTabelCell;
	}
	return nil;
}

- (void)awakeFromNib {
	firstView = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	if (firstView) {
		blogHTTPAuthEnabled.on = authEnabled;
		blogHTTPAuthUsername.text = authUsername;
		blogHTTPAuthPassword.text = authPassword;
	}
	firstView = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	if ([blogHTTPAuthUsername.text isEmpty] || [blogHTTPAuthPassword.text isEmpty]) {
		blogHTTPAuthEnabled.on = NO;
	}
	[editBlogViewController setAuthEnabledText:blogHTTPAuthEnabled.on];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[authUsername release];
	[authPassword release];
    [super dealloc];
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
	
    if (textField == blogHTTPAuthUsername) {
        [blogHTTPAuthPassword becomeFirstResponder];
    }
	
    return YES;
}


@end
