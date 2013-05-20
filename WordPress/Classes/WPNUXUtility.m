//
//  WPNUXUtility.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPNUXUtility.h"

@implementation WPNUXUtility

#pragma mark - Fonts

+ (UIFont *)textFieldFont
{
    return [UIFont fontWithName:@"OpenSans" size:18.0];
}

+ (UIFont *)descriptionTextFont
{
    return [UIFont fontWithName:@"OpenSans" size:15.0];
}

+ (UIFont *)titleFont
{
    return [UIFont fontWithName:@"OpenSans-Light" size:29];
}

+ (UIFont *)swipeToContinueFont
{
    return [UIFont fontWithName:@"OpenSans" size:10.0];
}

+ (UIFont *)tosLabelFont
{
    return [UIFont fontWithName:@"OpenSans" size:12.0];
}

+ (UIFont *)tosLabelSmallerFont
{
    return [UIFont fontWithName:@"OpenSans" size:9.0];
}

#pragma mark - Colors

+ (UIColor *)textShadowColor
{
    return [UIColor colorWithRed:0.0 green:115.0/255.0 blue:164.0/255.0 alpha:0.5];
}

+ (UIColor *)bottomPanelLineColor
{
    return [UIColor colorWithRed:17.0/255.0 green:17.0/255.0 blue:17.0/255.0 alpha:0.95];
}

+ (UIColor *)descriptionTextColor
{
    return [UIColor colorWithRed:187.0/255.0 green:221.0/255.0 blue:237.0/255.0 alpha:1.0];
}

+ (UIColor *)bottomPanelBackgroundColor
{
    return [UIColor colorWithRed:42.0/255.0 green:42.0/255.0 blue:42.0/255.0 alpha:1.0];
}

+ (UIColor *)swipeToContinueTextColor
{
    return [UIColor colorWithRed:255.0 green:255.0 blue:255.0 alpha:0.3];
}

+ (UIColor *)confirmationLabelColor
{
    return [UIColor colorWithRed:188.0/255.0 green:221.0/255.0 blue:236.0/255.0 alpha:1.0];
}

+ (UIColor *)backgroundColor
{
    return [UIColor colorWithRed:30.0/255.0 green:140.0/255.0 blue:190.0/255.0 alpha:1.0];
}

+ (UIColor *)tosLabelColor
{
    return [UIColor colorWithRed:255.0 green:255.0 blue:255.0 alpha:0.3];
}

#pragma mark - Helper Methods

+ (void)centerViews:(NSArray *)controls withStartingView:(UIView *)startingView andEndingView:(UIView *)endingView forHeight:(CGFloat)viewHeight
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

+ (void)configurePageControlTintColors:(UIPageControl *)pageControl
{
    // This only works on iOS6+
    if ([pageControl respondsToSelector:@selector(pageIndicatorTintColor)]) {
        UIColor *currentPageTintColor = [UIColor colorWithRed:46.0/255.0 green:162.0/255.0 blue:204.0/255.0 alpha:1.0];
        UIColor *pageIndicatorTintColor = [UIColor colorWithRed:38.0/255.0 green:151.0/255.0 blue:197.0/255.0 alpha:1.0];
        pageControl.pageIndicatorTintColor = pageIndicatorTintColor;
        pageControl.currentPageIndicatorTintColor = currentPageTintColor;
    }
}

@end
