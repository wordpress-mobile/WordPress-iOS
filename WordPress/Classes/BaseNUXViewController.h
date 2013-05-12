//
//  BaseNUXViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseNUXViewController : UIViewController

- (UIFont *)textFieldFont;
- (UIColor *)bottomPanelLineColor;
- (UIColor *)descriptionTextColor;
- (void)centerViews:(NSArray *)controls withStartingView:(UIView *)startingView andEndingView:(UIView *)endingView forHeight:(CGFloat)viewHeight;

@end
