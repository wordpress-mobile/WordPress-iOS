//
//  GeneralWalkthroughPage3ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "GeneralWalkthroughPage3ViewController.h"
#import "WPWalkthroughTextField.h"
#import "WPNUXMainButton.h"
#import "WPNUXUtility.h"

@interface GeneralWalkthroughPage3ViewController () <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *username;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *password;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *siteAddress;
@property (nonatomic, strong) IBOutlet WPNUXMainButton *signInButton;

@end

@implementation GeneralWalkthroughPage3ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.username.placeholder = NSLocalizedString(@"Username / Email", @"NUX First Walkthrough Page 3 Username Placeholder");
    self.username.font = [WPNUXUtility textFieldFont];
    self.username.delegate = self;

    self.password.placeholder = NSLocalizedString(@"Password", nil);
    self.password.font = [WPNUXUtility textFieldFont];
    self.password.delegate = self;
    
    self.siteAddress.placeholder = NSLocalizedString(@"Site Address (URL)", @"NUX First Walkthrough Page 3 Site Address Placeholder");
    self.siteAddress.font = [WPNUXUtility textFieldFont];
    self.siteAddress.delegate = self;
    
    [self.signInButton setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
}

- (UIView *)topViewToCenterAgainst
{
    return self.logo;
}

- (UIView *)bottomViewToCenterAgainst
{
    return self.siteAddress;
}

#pragma mark - UITextFieldDelegate methods


@end
