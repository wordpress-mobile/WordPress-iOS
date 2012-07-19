//
//  UIPopoverController+Styled.m
//  WordPress
//
//  Created by Eric Johnson on 7/19/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UIPopoverController+Styled.h"
#import "WPPopoverBackgroundView.h"

#import <objc/runtime.h>

@implementation UIPopoverController (Styled)

- (id)styledInitWithContentViewController:(UIViewController *)viewController {
    self = [self styledInitWithContentViewController:viewController];
    if (self) {
        if ([self respondsToSelector:@selector(setPopoverBackgroundViewClass:)]) {
            self.popoverBackgroundViewClass = [WPPopoverBackgroundView class];
        }
    }
    return self;
}


+ (void)load {
    Method origMethod = class_getInstanceMethod(self, @selector(initWithContentViewController:));
    Method newMethod = class_getInstanceMethod(self, @selector(styledInitWithContentViewController:));
    method_exchangeImplementations(origMethod, newMethod);

}

@end
