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

@interface GeneralWalkthroughPage3ViewController () <UITextFieldDelegate> {
    NSLayoutConstraint *_adjustedCenteringConstraint;
    BOOL _correctedCenteringLayout;
}


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
    
    [self.view removeConstraint:self.verticalCenteringConstraint];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    [self.view removeConstraint:_adjustedCenteringConstraint];
    
    CGFloat heightOfMiddleControls = CGRectGetMaxY(self.siteAddress.frame) - CGRectGetMinY(self.logo.frame);
    CGFloat verticalOffset = (self.heightToUseForCentering - heightOfMiddleControls)/2.0;
    
    _adjustedCenteringConstraint = [NSLayoutConstraint constraintWithItem:self.logo attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:verticalOffset];
    
    [self.view addConstraint:_adjustedCenteringConstraint];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Because we want to customize the centering of the logo -> bottom divider we need to wait until the first layout pass
    // happens before our customized constraint will work correctly as otherwise the values will look like they belong to an
    // iPhone 5 and the logo -> bottom divider controls won't be centered.
    if (!_correctedCenteringLayout) {
        _correctedCenteringLayout = true;
        [self.view setNeedsUpdateConstraints];
    }
}

#pragma mark - UITextFieldDelegate methods


@end
