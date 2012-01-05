//
//  UIViewController+PSStackedView.h
//  3MobileTV
//
//  Created by Peter Steinberger on 9/16/11.
//  Copyright (c) 2011 Hutchison. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSStackedViewGlobal.h"

@class PSSVContainerView, PSStackedViewController;

/// category for PSStackedView extensions
@interface UIViewController (PSStackedView)

- (CGFloat)stackWidth;
- (void)setStackWidth:(CGFloat)stackWidth;

/// returns the containerView, where view controllers are embedded
- (PSSVContainerView *)containerView;

/// returns the stack controller if the viewController is embedded
- (PSStackedViewController *)stackController;

@end