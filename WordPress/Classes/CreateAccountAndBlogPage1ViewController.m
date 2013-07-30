//
//  CreateAccountAndBlogPage1ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateAccountAndBlogPage1ViewController.h"
#import "WPWalkthroughTextField.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXUtility.h"

@interface CreateAccountAndBlogPage1ViewController () {
    BOOL _correctedCenteringLayout;
    NSLayoutConstraint *_adjustedCenteringConstraint;
}

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *tosLabel;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *username;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *email;
@property (nonatomic, strong) IBOutlet WPWalkthroughTextField *password;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *nextButton;

@end

@implementation CreateAccountAndBlogPage1ViewController

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
    
    self.titleLabel.text = NSLocalizedString(@"Create an account on WordPress.com", @"NUX Create Account Page 1 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    
    self.email.placeholder = NSLocalizedString(@"Email Address", @"NUX Create Account Page 1 Email Placeholder");
    self.email.font = [WPNUXUtility textFieldFont];
    
    self.username.placeholder = NSLocalizedString(@"Username", nil);
    self.username.font = [WPNUXUtility textFieldFont];
    
    self.password.placeholder = NSLocalizedString(@"Password", nil);;
    self.password.font = [WPNUXUtility textFieldFont];
    
    [self.nextButton setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
    
    self.tosLabel.text = NSLocalizedString(@"You agree to the fascinating terms of service by pressing the next button.", @"NUX Create Account TOS Label");
    self.tosLabel.font = [WPNUXUtility tosLabelFont];
    self.tosLabel.layer.shadowRadius = 2.0;
    
    [self.view removeConstraint:self.verticalCenteringConstraint];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    [self.view removeConstraint:_adjustedCenteringConstraint];
    
    CGFloat heightOfMiddleControls = CGRectGetMaxY(self.tosLabel.frame) - CGRectGetMinY(self.logo.frame);
    CGFloat verticalOffset = (CGRectGetHeight(self.view.bounds) - heightOfMiddleControls)/2.0;
    
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

@end
