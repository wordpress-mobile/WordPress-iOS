//
//  NewLoginCompletedWalkthroughPage2ViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/29/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "LoginCompletedWalkthroughPage2ViewController.h"
#import "WPNUXUtility.h"

@interface LoginCompletedWalkthroughPage2ViewController () {
    NSLayoutConstraint *_adjustedCenteringConstraint;
    BOOL _correctedCenteringLayout;
}

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *verticalCenteringConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *logo;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *description;
@property (nonatomic, strong) IBOutlet UIImageView *bottomDivider;

@end

@implementation LoginCompletedWalkthroughPage2ViewController

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
    
    self.titleLabel.text = NSLocalizedString(@"Explore the WordPress.com Reader", @"NUX Second Walkthrough Page 2 Title");
    self.titleLabel.font = [WPNUXUtility titleFont];
    self.titleLabel.layer.shadowRadius = 2.0;
    
    self.description.text = NSLocalizedString(@"Browse the entire WordPress ecosystem. Thousands of topics at the flick of a finger.", @"NUX Second Walkthrough Page 2 Description");
    self.description.font = [WPNUXUtility descriptionTextFont];
    self.description.layer.shadowRadius = 2.0;

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

@end
