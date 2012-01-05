//
//  UIViewController+PSStackedView.m
//  3MobileTV
//
//  Created by Peter Steinberger on 9/16/11.
//  Copyright (c) 2011 Hutchison. All rights reserved.
//

#import "UIViewController+PSStackedView.h"
#import "PSSVContainerView.h"
#import "PSStackedViewController.h"
#import <objc/runtime.h>

#define kPSSVAssociatedStackViewControllerWidth @"kPSSVAssociatedStackViewControllerWidth"

@implementation UIViewController (PSStackedView)

// returns the containerView, where view controllers are embedded
- (PSSVContainerView *)containerView; {
    return ([self.view.superview isKindOfClass:[PSSVContainerView class]] ? (PSSVContainerView *)self.view.superview : nil);
}

// returns the stack controller if the viewController is embedded
- (PSStackedViewController *)stackController; {
    PSStackedViewController *stackController = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerKey);
    return stackController;
}

#ifdef ALLOW_SWIZZLING_NAVIGATIONCONTROLLER
/// to maintain minimal changes for your app, we can do some clever swizzling here.
- (UINavigationController *)navigationControllerSwizzled {
    if (!self.navigationControllerSwizzled) {
        return (UINavigationController *)self.stackController;
    }else {
        return self.navigationController;
    }
}
#endif

- (CGFloat)stackWidth {
    NSNumber *stackWidthNumber = objc_getAssociatedObject(self, kPSSVAssociatedStackViewControllerWidth);
    CGFloat stackWidth = stackWidthNumber ? [stackWidthNumber floatValue] : 0.f;
    return stackWidth;
}

- (void)setStackWidth:(CGFloat)stackWidth {
    NSNumber *stackWidthNumber = [NSNumber numberWithFloat:stackWidth];
    objc_setAssociatedObject(self, kPSSVAssociatedStackViewControllerWidth, stackWidthNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end