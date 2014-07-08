//
//  SPAuthenticationViewController.h
//  Simperium
//
//  Created by Michael Johnston on 24/11/11.
//  Copyright 2011 Simperium. All rights reserved.
//
//  You can write a subclass of SPAuthenticationViewController and then set authenticationViewControllerClass
//  on your Simperium instance in order to fully customize the behavior of the authentication UI.
//
//  Simperium will use the subclass and display your UI automatically.

#import <UIKit/UIKit.h>


@class SPAuthenticator;

#pragma mark ====================================================================================
#pragma mark SPAuthenticationViewController
#pragma mark ====================================================================================

@interface SPAuthenticationViewController : UIViewController

@property (nonatomic, strong) SPAuthenticator	*authenticator;
@property (nonatomic, strong) UITableView		*tableView;
@property (nonatomic, strong) UIImageView		*logoView;
@property (nonatomic, assign) BOOL				signingIn;

@end
