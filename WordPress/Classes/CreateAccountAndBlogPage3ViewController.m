//
//  CreateAccountAndBlogPage3ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CreateAccountAndBlogPage3ViewController.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXUtility.h"

@interface CreateAccountAndBlogPage3ViewController () {
    BOOL _correctedCenteringLayout;
    NSLayoutConstraint *_adjustedCenteringConstraint;
}

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *finalLineSeparator;
@property (nonatomic, strong) IBOutlet UILabel *emailConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *usernameConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *siteTitleConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *siteAddressConfirmation;
@property (nonatomic, strong) IBOutlet UILabel *siteLanguageConfirmation;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *previousButton;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *nextButton;


@end

@implementation CreateAccountAndBlogPage3ViewController

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
    
    self.titleLabel.text = NSLocalizedString(@"Review your information", @"NUX Create Account Page 3 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    
    self.emailConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.usernameConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.siteTitleConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.siteAddressConfirmation.font = [WPNUXUtility confirmationLabelFont];
    self.siteLanguageConfirmation.font = [WPNUXUtility confirmationLabelFont];
    
    [self.view removeConstraint:self.verticalCenteringConstraint];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    [self.view removeConstraint:_adjustedCenteringConstraint];
    
    CGFloat heightOfMiddleControls = CGRectGetMaxY(self.finalLineSeparator.frame) - CGRectGetMinY(self.logo.frame);
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
