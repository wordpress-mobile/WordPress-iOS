//
//  UIToolbar+Styled.m
//  WordPress
//
//  Created by Eric Johnson on 7/6/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UIToolbar+Styled.h"

#import <objc/runtime.h>

@implementation UIToolbar (Styled)

- (void)layoutSubviewsWithShadows {
    // Since we exchanged implementations, this actually calls UIKit's layoutSubviews
    [self layoutSubviewsWithShadows];

    // Super sneaky/hacky way of getting dropshadows on all our styled toolbars.
    if ([[self class] respondsToSelector:@selector(appearance)]) {
        NSInteger shadowTag = 1;        
        UIView *shadowView = [self viewWithTag:shadowTag];

        if (shadowView == nil) {
            UIImageView *shadowImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"toolbar_shadow"]];
            shadowImg.frame = CGRectMake(0.0f,-4.0f, self.frame.size.width, 4.0f);
            // Even though it feels like we want flexible top margin, we're using negative positioning
            // so flexible bottom margin seems to do the trick for this
            shadowImg.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
            shadowImg.tag = shadowTag;
            [self addSubview:shadowImg];
        }
    }
}

+ (void)load {
    Method origMethod = class_getInstanceMethod(self, @selector(layoutSubviews));
    Method newMethod = class_getInstanceMethod(self, @selector(layoutSubviewsWithShadows));
    method_exchangeImplementations(origMethod, newMethod);
}

@end
