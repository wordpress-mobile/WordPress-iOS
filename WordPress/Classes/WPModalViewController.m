//
//  WPModalViewController.m
//  WordPress
//
//  Created by Brennan Stehling on 8/28/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPModalViewController.h"

CGFloat const WPModalAnimationDuration = 0.45;

@interface WPModalViewController () <UIGestureRecognizerDelegate>

@end

@implementation WPModalViewController

+ (WPModalViewController *)modalViewController:(id<WPModalViewControllerDelegate>)delegate {
    NSAssert(!IS_IPAD, @"WPModalViewController does not support the iPad. Use UIPopoverController instead.");
    
    WPModalViewController *mvc = [[WPModalViewController alloc] init];
    mvc.delegate = delegate;
    mvc.animationDuration = WPModalAnimationDuration;
    return mvc;
}

- (void)showModal:(BOOL)animated inView:(UIView *)aView {
    if ([self.delegate respondsToSelector:@selector(modalViewController:willShow:withCompletionBlock:)]) {
        [self.delegate modalViewController:self willShow:animated withCompletionBlock:^{
            [self finishShowingModal:animated inView:aView];
        }];
    }
    else {
        [self finishShowingModal:animated inView:aView];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChangeNotification:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)hideModal:(BOOL)animated {
    if ([self.delegate respondsToSelector:@selector(modalViewController:willHide:withCompletionBlock:)]) {
        [self.delegate modalViewController:self willHide:animated withCompletionBlock:^{
            [self finishHidingModal:animated];
        }];
    }
    else {
        [self finishHidingModal:animated];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

#pragma mark -
#pragma mark Private

- (void)finishShowingModal:(BOOL)animated inView:(UIView *)aView {
    
    // make modal cover the whole view (self.view.window)
    self.view.bounds = aView.window.bounds;
    [aView.window addSubview:self.view];
    
    self.view.alpha = 0.0;
    
    [self sizeToFitOrientation:TRUE];
    
    CGFloat duration = animated ? self.animationDuration : 0.0;
    
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        self.view.alpha = 1.0;
    } completion:^(BOOL finished) {
        if ([self.delegate respondsToSelector:@selector(modalViewController:didShow:)]) {
            [self.delegate modalViewController:self didShow:animated];
        }
    }];
}

- (void)finishHidingModal:(BOOL)animated {
    CGFloat duration = animated ? self.animationDuration : 0.0;
    
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        if ([self.delegate respondsToSelector:@selector(modalViewController:didHide:)]) {
            [self.delegate modalViewController:self didHide:animated];
        }
        [self.view removeFromSuperview];
    }];
}

#pragma mark -
#pragma mark User Actions

- (IBAction)tapGestureRecognized:(id)sender {
    if ([self.delegate respondsToSelector:@selector(modalViewController:wasDismissed:)]) {
        [self.delegate modalViewController:self wasDismissed:TRUE];
    }
}

#pragma mark Sizing (for orientation changes)
#pragma mark -

- (void)sizeToFitOrientation:(BOOL)transform {
	if (transform) {
		self.view.transform = CGAffineTransformIdentity;
	}
	
	CGRect frame = [UIScreen mainScreen].applicationFrame;
	CGPoint center = CGPointMake(
								 frame.origin.x + ceil(frame.size.width/2),
								 frame.origin.y + ceil(frame.size.height/2));
	
	CGFloat width = frame.size.width;
	CGFloat height = frame.size.height;
	
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		self.view.frame = CGRectMake(0.0f, 0.0f, height, width);
	} else {
		self.view.frame = CGRectMake(0.0f, 0.0f, width, height);
	}
	self.view.center = center;
	
	if (transform) {
		self.view.transform = [self transformForOrientation];
	}
}

- (CGAffineTransform)transformForOrientation {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (orientation == UIInterfaceOrientationLandscapeLeft) {
		return CGAffineTransformMakeRotation(M_PI*1.5);
	} else if (orientation == UIInterfaceOrientationLandscapeRight) {
		return CGAffineTransformMakeRotation(M_PI/2);
	} else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
//		return CGAffineTransformMakeRotation(-M_PI);
        return CGAffineTransformIdentity;
	} else {
		return CGAffineTransformIdentity;
	}
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // only respond tapping the main view, not any subview which may use the touch events
    return touch.view == self.view;
}

#pragma mark -
#pragma mark Notifications

- (void)deviceOrientationDidChangeNotification:(NSNotification *)notification {
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    
    [UIView animateWithDuration:duration animations:^{
        [self sizeToFitOrientation:YES];
    } completion:^(BOOL finished) {
    }];
}

@end
