//
//  UIViewController+WPAnimation.h
//  WordPress
//
//  Created by JanakiRam on 17/12/08.
//

#import <UIKit/UIKit.h>

@interface UIViewController (WPAnimation)

- (void)pushTransition:(UIViewController *)viewController;
- (void)popTransition:(UIView *)view;

@end
