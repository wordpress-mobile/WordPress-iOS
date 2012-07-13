//
//  UIBarButtonItem+Styled.m
//  WordPress
//
//  Created by Jorge Bernal on 7/12/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UIBarButtonItem+Styled.h"

#import <objc/runtime.h>

@implementation UIBarButtonItem (Styled)

- (id)styledInitWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    self = [self styledInitWithImage:image style:style target:target action:action];
    if (self) {
        if (style == UIBarButtonItemStyleDone) {
            [[self class] styleButtonAsPrimary:self];
        }
    }
    return self;
}

- (id)styledInitWithImage:(UIImage *)image landscapeImagePhone:(UIImage *)landscapeImagePhone style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    self = [self styledInitWithImage:image landscapeImagePhone:landscapeImagePhone style:style target:target action:action];
    if (self) {
        if (style == UIBarButtonItemStyleDone) {
            [[self class] styleButtonAsPrimary:self];
        }
    }
    return self;
}

- (id)styledInitWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    self = [self styledInitWithTitle:title style:style target:target action:action];
    if (self) {
        if (style == UIBarButtonItemStyleDone) {
            [[self class] styleButtonAsPrimary:self];
        }
    }
    return self;
}

+ (void)load {
    if ([self respondsToSelector:@selector(appearance)]) {
        Method origMethod = class_getInstanceMethod(self, @selector(initWithImage:style:target:action:));
        Method newMethod = class_getInstanceMethod(self, @selector(styledInitWithImage:style:target:action:));
        method_exchangeImplementations(origMethod, newMethod);
        origMethod = class_getInstanceMethod(self, @selector(initWithImage:landscapeImagePhone:style:target:action:));
        newMethod = class_getInstanceMethod(self, @selector(styledInitWithImage:landscapeImagePhone:style:target:action:));
        method_exchangeImplementations(origMethod, newMethod);
        origMethod = class_getInstanceMethod(self, @selector(initWithTitle:style:target:action:));
        newMethod = class_getInstanceMethod(self, @selector(styledInitWithTitle:style:target:action:));
        method_exchangeImplementations(origMethod, newMethod);
    }
}

+ (void)styleButtonAsPrimary:(UIBarButtonItem *)buttonItem {
    
    [buttonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [buttonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

    [buttonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_landscape"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [buttonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_landscape_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateSelected barMetrics:UIBarMetricsLandscapePhone];

    [buttonItem setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor],
      UITextAttributeTextColor,
      [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0],
      UITextAttributeTextShadowColor,
      [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
      UITextAttributeTextShadowOffset,
      nil] forState:UIControlStateHighlighted];

    [buttonItem setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor],
      UITextAttributeTextColor,
      [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0],
      UITextAttributeTextShadowColor,
      [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
      UITextAttributeTextShadowOffset,
      nil] forState:UIControlStateNormal];

    [buttonItem setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0],
      UITextAttributeTextColor,
      [UIColor whiteColor],
      UITextAttributeTextShadowColor,
      [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
      UITextAttributeTextShadowOffset,
      nil] forState:UIControlStateDisabled];
}

+ (void)restoreDefaultButtonStyle:(UIBarButtonItem *)buttonItem {
    void (^restoreBackgroundImage)(UIControlState,UIBarMetrics) = ^(UIControlState state, UIBarMetrics metrics) {
        [buttonItem setBackgroundImage:[[UIBarButtonItem appearance] backgroundImageForState:state barMetrics:metrics] forState:state barMetrics:metrics];
    };
    void (^restoreTextAttributes)(UIControlState) = ^(UIControlState state) {
        [buttonItem setTitleTextAttributes:[[UIBarButtonItem appearance] titleTextAttributesForState:state] forState:state];
    };
    restoreBackgroundImage(UIControlStateNormal,    UIBarMetricsDefault);
    restoreBackgroundImage(UIControlStateSelected,  UIBarMetricsDefault);
    restoreBackgroundImage(UIControlStateHighlighted,  UIBarMetricsDefault);
    restoreBackgroundImage(UIControlStateNormal,    UIBarMetricsLandscapePhone);
    restoreBackgroundImage(UIControlStateSelected,  UIBarMetricsLandscapePhone);
    restoreBackgroundImage(UIControlStateHighlighted,  UIBarMetricsLandscapePhone);
    
    restoreTextAttributes(UIControlStateNormal);
    restoreTextAttributes(UIControlStateHighlighted);
}

@end
