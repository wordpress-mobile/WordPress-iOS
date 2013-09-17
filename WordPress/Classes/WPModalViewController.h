//
//  WPModalViewController.h
//  WordPress
//
//  Created by Brennan Stehling on 8/28/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const WPModalAnimationDuration;

@protocol WPModalViewControllerDelegate;

@interface WPModalViewController : UIViewController

@property (assign, nonatomic) id<WPModalViewControllerDelegate> delegate;

@property (assign, nonatomic) CGFloat animationDuration;

+ (WPModalViewController *)modalViewController:(id<WPModalViewControllerDelegate>)delegate;

- (void)showModal:(BOOL)animated inView:(UIView *)aView;

- (void)hideModal:(BOOL)animated;

@end

@protocol WPModalViewControllerDelegate <NSObject>

@optional

- (void)modalViewController:(WPModalViewController *)mvc wasDismissed:(BOOL)animated;

- (void)modalViewController:(WPModalViewController *)mvc willShow:(BOOL)animated withCompletionBlock:(void (^)())completionBlock;
- (void)modalViewController:(WPModalViewController *)mvc didShow:(BOOL)animated;
- (void)modalViewController:(WPModalViewController *)mvc willHide:(BOOL)animated withCompletionBlock:(void (^)())completionBlock;
- (void)modalViewController:(WPModalViewController *)mvc didHide:(BOOL)animated;

@end
