//
//  BaseNUXViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "BaseNUXViewController.h"

@interface BaseNUXViewController () {
    BOOL _correctedCenteringLayout;
}

@end

@implementation BaseNUXViewController

- (void)updateViewConstraints
{
    [super updateViewConstraints];

    CGFloat heightOfMiddleControls = CGRectGetMaxY([self bottomViewToCenterAgainst].frame) - CGRectGetMinY([self topViewToCenterAgainst].frame);
    CGFloat verticalOffset = ([self heightToUseForCentering] - heightOfMiddleControls)/2.0;
    
    self.verticalCenteringConstraint.constant = verticalOffset;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Because we want to customize the centering of the logo -> bottom divider we need to wait until the first layout pass
    // happens before our customized constraint will work correctly as otherwise the values will look like they belong to an
    // iPhone 5 and the logo -> bottom divider controls won't be centered.
    if (!_correctedCenteringLayout) {
        _correctedCenteringLayout = YES;
        [self.view setNeedsUpdateConstraints];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.view setNeedsUpdateConstraints];
}

// Must override
- (UIView *)topViewToCenterAgainst
{
    return nil;
}

// Must override
- (UIView *)bottomViewToCenterAgainst
{
    return nil;
}

// Must override
- (CGFloat)heightToUseForCentering
{
    return CGRectGetHeight(self.view.bounds);
}

// Must override
- (NSLayoutConstraint *)verticalCenteringConstraint
{
    return nil;
}

@end
