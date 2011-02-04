//
//  UIViewController+WPAnimation.m
//  WordPress
//
//  Created by JanakiRam on 17/12/08.
//

#import "UIViewController+WPAnimation.h"

#import <QuartzCore/QuartzCore.h>

@implementation UIViewController (WPAnimation)

- (void)pushTransition:(UIViewController *)viewController {
    [self.navigationController pushViewController:viewController animated:NO];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.0];

    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];

    if (self.interfaceOrientation == UIDeviceOrientationPortrait)
        [animation setSubtype:kCATransitionFromRight];else if (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        [animation setSubtype:kCATransitionFromLeft];else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        [animation setSubtype:kCATransitionFromBottom];else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
        [animation setSubtype:kCATransitionFromTop];

    [animation setDuration:0.3];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[viewController.navigationController.view layer] addAnimation:animation forKey:@"transitionViewAnimation"];
    [UIView commitAnimations];
}

- (void)popTransition:(UIView *)view {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.0];

    CATransition *animation = [CATransition animation];

    [animation setType:kCATransitionPush];

    if (self.interfaceOrientation == UIDeviceOrientationPortrait)
        [animation setSubtype:kCATransitionFromLeft];else if (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        [animation setSubtype:kCATransitionFromRight];else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        [animation setSubtype:kCATransitionFromTop];else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
        [animation setSubtype:kCATransitionFromBottom];

    [animation setDuration:0.3];

    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[view layer] addAnimation:animation forKey:@"transitionViewAnimation"];
    [UIView commitAnimations];
    [self.navigationController popViewControllerAnimated:NO];
}

@end
