//
//  GeneralWalkthroughPage1ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "GeneralWalkthroughPage1ViewController.h"
#import "WPNUXUtility.h"
#import "WPNUXPrimaryButton.h"
#import "WPNUXSecondaryButton.h"

@interface GeneralWalkthroughPage1ViewController () {
    NSLayoutConstraint *_adjustedCenteringConstraint;
    BOOL _correctedCenteringLayout;
}

@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, strong) IBOutlet UILabel *swipeToContinueLabel;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIImageView *helpButton;
@property (nonatomic, strong) IBOutlet UIImageView *bottomDivider;
@property (nonatomic, strong) IBOutlet WPNUXSecondaryButton *createAccountButton;
@property (nonatomic, strong) IBOutlet WPNUXPrimaryButton *signInButton;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;


@end

@implementation GeneralWalkthroughPage1ViewController

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

    self.titleLabel.text = NSLocalizedString(@"Welcome to WordPress", @"NUX First Walkthrough Page 1 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    self.titleLabel.layer.shadowRadius = 2.0;

    self.descriptionLabel.text = NSLocalizedString(@"Hold the web in the palm of your hand. Full publishing power in a pint-sized package.", @"NUX First Walkthrough Page 1 Description");
    self.descriptionLabel.font = [WPNUXUtility descriptionTextFont];
    self.descriptionLabel.layer.shadowRadius = 2.0;
    
    self.swipeToContinueLabel.text = [NSLocalizedString(@"swipe to continue", nil) uppercaseString];
    self.swipeToContinueLabel.font = [WPNUXUtility swipeToContinueFont];
    
    [self.createAccountButton setTitle:NSLocalizedString(@"Create Account", nil) forState:UIControlStateNormal];

    [self.signInButton setTitle:NSLocalizedString(@"Sign In", nil) forState:UIControlStateNormal];
    
    [WPNUXUtility configurePageControlTintColors:self.pageControl];
    
    [self.view removeConstraint:self.verticalCenteringConstraint];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    [self.view removeConstraint:_adjustedCenteringConstraint];
    
    CGFloat heightOfMiddleControls = CGRectGetMaxY(self.bottomDivider.frame) - CGRectGetMinY(self.logo.frame);
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

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.view setNeedsUpdateConstraints];
}

@end
