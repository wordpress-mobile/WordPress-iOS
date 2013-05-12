//
//  WPNUXUtility.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPNUXUtility : NSObject

+ (UIFont *)textFieldFont;
+ (UIFont *)descriptionTextFont;
+ (UIFont *)titleFont;
+ (UIFont *)swipeToContinueFont;

+ (UIColor *)textShadowColor;
+ (UIColor *)bottomPanelLineColor;
+ (UIColor *)descriptionTextColor;
+ (UIColor *)bottomPanelBackgroundColor;
+ (UIColor *)swipeToContinueTextColor;
+ (UIColor *)swipeToContinueShadowTextColor;

+ (void)centerViews:(NSArray *)controls withStartingView:(UIView *)startingView andEndingView:(UIView *)endingView forHeight:(CGFloat)viewHeight;
+ (void)configurePageControlTintColors:(UIPageControl *)pageControl;

@end
