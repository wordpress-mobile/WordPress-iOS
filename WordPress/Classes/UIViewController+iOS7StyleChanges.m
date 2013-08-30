//
//  UIViewController+iOS7StyleChanges.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/29/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "UIViewController+iOS7StyleChanges.h"
#import <objc/runtime.h>

@implementation UIViewController (iOS7StyleChanges)

- (void)alteredSetTitle:(NSString *)title
{
    [self alteredSetTitle:title];
}

- (void)alteredViewWillAppear:(BOOL)animated
{
    // Since we exchanged implementations, this actually calls UIViewController's viewDidLoad
    [self alteredViewWillAppear:animated];
    
    if (!IS_IOS7)
        return;
    
    self.title = [self.title uppercaseString];
    self.navigationItem.title = [self.navigationItem.title uppercaseString];
    
    [self.navigationItem.leftBarButtonItem setTitlePositionAdjustment:UIOffsetMake(-1, 0) forBarMetrics:UIBarMetricsDefault];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{UITextAttributeFont: [UIFont fontWithName:@"OpenSans" size:12.0], UITextAttributeTextColor : [UIColor whiteColor]} forState:UIControlStateNormal];

    [self.navigationItem.rightBarButtonItem setTitlePositionAdjustment:UIOffsetMake(1, 0) forBarMetrics:UIBarMetricsDefault];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeFont: [UIFont fontWithName:@"OpenSans" size:12.0], UITextAttributeTextColor : [UIColor whiteColor]} forState:UIControlStateNormal];
}

+ (void)load {
    Method origMethod = class_getInstanceMethod(self, @selector(viewWillAppear:));
    Method newMethod = class_getInstanceMethod(self, @selector(alteredViewWillAppear:));
    method_exchangeImplementations(origMethod, newMethod);
    
    origMethod = class_getInstanceMethod(self, @selector(setTitle:));
    newMethod = class_getInstanceMethod(self, @selector(alteredSetTitle:));
    method_exchangeImplementations(origMethod, newMethod);
}

@end
