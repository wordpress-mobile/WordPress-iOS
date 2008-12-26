//
//  UIViewController+WPAnimation.h
//  WordPress
//
//  Created by JanakiRam on 17/12/08.
//  Copyright 2008 Prithvi Information Solutions Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@interface UIViewController (WPAnimation) 

- (void) pushTransition:(UIViewController *)viewController;
- (void) popTransition:(UIView *)view;


@end

