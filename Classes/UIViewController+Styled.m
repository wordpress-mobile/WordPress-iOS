//
//  UIViewController+Styled.m
//  WordPress
//
//  Created by Jorge Bernal on 7/12/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UIViewController+Styled.h"

#import <objc/runtime.h>

@implementation UIViewController (Styled)

- (void)setStyledEditing:(BOOL)editing animated:(BOOL)animated {
    // Since we exchanged implementations, this actually calls UIKit's setEditing:animated:
    [self setStyledEditing:editing animated:animated];
    if (editing) {
        [self.editButtonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.editButtonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        [self.editButtonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_landscape"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
        [self.editButtonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_landscape_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateSelected barMetrics:UIBarMetricsLandscapePhone];
        [self.editButtonItem setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [UIColor colorWithWhite:1.f alpha:1.f],
          UITextAttributeTextColor,
          [UIColor colorWithWhite:0.f alpha:1.f],
          UITextAttributeTextShadowColor,
          [NSValue valueWithUIOffset:UIOffsetMake(0.f, 1.f)],
          UITextAttributeTextShadowOffset,
          nil] forState:UIControlStateNormal];
        [self.editButtonItem setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [UIColor colorWithWhite:1.f alpha:1.f],
          UITextAttributeTextColor,
          [UIColor colorWithWhite:0.f alpha:1.f],
          UITextAttributeTextShadowColor,
          [NSValue valueWithUIOffset:UIOffsetMake(0.f, 1.f)],
          UITextAttributeTextShadowOffset,
          nil] forState:UIControlStateSelected];
    } else {
        void (^restoreBackgroundImage)(UIControlState,UIBarMetrics) = ^(UIControlState state, UIBarMetrics metrics) {
            [self.editButtonItem setBackgroundImage:[[UIBarButtonItem appearance] backgroundImageForState:state barMetrics:metrics] forState:state barMetrics:metrics];
        };
        void (^restoreTextAttributes)(UIControlState) = ^(UIControlState state) {
            [self.editButtonItem setTitleTextAttributes:[[UIBarButtonItem appearance] titleTextAttributesForState:state] forState:state];
        };
        restoreBackgroundImage(UIControlStateNormal,    UIBarMetricsDefault);
        restoreBackgroundImage(UIControlStateSelected,  UIBarMetricsDefault);
        restoreBackgroundImage(UIControlStateNormal,    UIBarMetricsLandscapePhone);
        restoreBackgroundImage(UIControlStateSelected,  UIBarMetricsLandscapePhone);
        restoreTextAttributes(UIControlStateNormal);
        restoreTextAttributes(UIControlStateSelected);
    }
}

+ (void)load {
    Method origMethod = class_getInstanceMethod(self, @selector(setEditing:animated:));
    Method newMethod = class_getInstanceMethod(self, @selector(setStyledEditing:animated:));
    method_exchangeImplementations(origMethod, newMethod);
}

@end
