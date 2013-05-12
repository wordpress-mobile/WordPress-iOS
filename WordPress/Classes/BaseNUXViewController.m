//
//  BaseNUXViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "BaseNUXViewController.h"

@interface BaseNUXViewController ()

@end

@implementation BaseNUXViewController

- (UIFont *)textFieldFont
{
    return [UIFont fontWithName:@"OpenSans" size:18.0];
}

- (UIColor *)bottomPanelLineColor
{
    return [UIColor colorWithRed:17.0/255.0 green:17.0/255.0 blue:17.0/255.0 alpha:0.95];
}

- (UIColor *)descriptionTextColor
{
    return [UIColor colorWithRed:187.0/255.0 green:221.0/255.0 blue:237.0/255.0 alpha:1.0];
}

- (void)centerViews:(NSArray *)controls withStartingView:(UIView *)startingView andEndingView:(UIView *)endingView forHeight:(CGFloat)viewHeight
{
    CGFloat heightOfControls = CGRectGetMaxY(endingView.frame) - CGRectGetMinY(startingView.frame);
    CGFloat startingYForCenteredControls = floorf((viewHeight - heightOfControls)/2.0);
    CGFloat offsetToCenter = CGRectGetMinY(startingView.frame) - startingYForCenteredControls;
    
    for (UIControl *control in controls) {
        CGRect frame = control.frame;
        frame.origin.y -= offsetToCenter;
        control.frame = frame;
    }
}

@end
