/*
 * AddUsersBlogsViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


@class WPAccount;

@interface AddUsersBlogsViewController : UIViewController

@property (nonatomic, strong) NSArray *usersBlogs;
@property (nonatomic, assign) BOOL isWPcom;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) BOOL geolocationEnabled;

- (AddUsersBlogsViewController *)initWithAccount:(WPAccount *)account;

@end
