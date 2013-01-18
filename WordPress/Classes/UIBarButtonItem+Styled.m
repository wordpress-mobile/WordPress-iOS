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

- (id)initStyledWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    self = [self initStyledWithImage:image style:style target:target action:action];
    if (self) {
        if (style == UIBarButtonItemStyleDone) {
            [[self class] styleButtonAsPrimary:self];
        } else if (style == UIBarButtonItemStylePlain) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setFrame:CGRectMake(0.0f, 0.0f, 30.0f, 30.0f)];
            [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
            [button setImage:image forState:UIControlStateNormal];
            [self setCustomView:button];
        }
    }
    return self;
}

- (id)initStyledWithImage:(UIImage *)image landscapeImagePhone:(UIImage *)landscapeImagePhone style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    self = [self initStyledWithImage:image landscapeImagePhone:landscapeImagePhone style:style target:target action:action];
    if (self) {
        if (style == UIBarButtonItemStyleDone) {
            [[self class] styleButtonAsPrimary:self];
        }
    }
    return self;
}

- (id)initStyledWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
    self = [self initStyledWithTitle:title style:style target:target action:action];
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
        Method newMethod = class_getInstanceMethod(self, @selector(initStyledWithImage:style:target:action:));
        method_exchangeImplementations(origMethod, newMethod);
        origMethod = class_getInstanceMethod(self, @selector(initWithImage:landscapeImagePhone:style:target:action:));
        newMethod = class_getInstanceMethod(self, @selector(initStyledWithImage:landscapeImagePhone:style:target:action:));
        method_exchangeImplementations(origMethod, newMethod);
        origMethod = class_getInstanceMethod(self, @selector(initWithTitle:style:target:action:));
        newMethod = class_getInstanceMethod(self, @selector(initStyledWithTitle:style:target:action:));
        method_exchangeImplementations(origMethod, newMethod);
    }
}

+ (void)styleButtonAsPrimary:(UIBarButtonItem *)buttonItem {
    
    [buttonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [buttonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

    [buttonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_landscape"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [buttonItem setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_landscape_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];

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
//      [UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0],
      [UIColor UIColorFromHex:0xeeeeee],
      UITextAttributeTextColor,
//      [UIColor whiteColor],
      [UIColor UIColorFromHex:0xbbbbbb],
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
    restoreBackgroundImage(UIControlStateHighlighted,  UIBarMetricsDefault);
    restoreBackgroundImage(UIControlStateNormal,    UIBarMetricsLandscapePhone);
    restoreBackgroundImage(UIControlStateHighlighted,  UIBarMetricsLandscapePhone);
    
    restoreTextAttributes(UIControlStateNormal);
    restoreTextAttributes(UIControlStateHighlighted);
}

@end
