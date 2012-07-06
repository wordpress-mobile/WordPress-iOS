//
//  UIToolbar+Styled.m
//  WordPress
//
//  Created by Eric Johnson on 7/6/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UIToolbar+Styled.h"

@implementation UIToolbar (Styled)

- (void)layoutSubviews {
    // Super sneaky/hacky way of getting dropshadows on all our styled toolbars.
    if ([[self class] respondsToSelector:@selector(appearance)]) {
        NSInteger shadowTag = 1;        
        UIView *shadowView = nil;
        for (UIView *view in self.subviews) {
            if (view.tag == shadowTag) {
                shadowView = view;
                break;
            }
        }
        if (shadowView == nil) {
            UIImageView *shadowImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"toolbar_shadow"]];
            shadowImg.frame = CGRectMake(0.0f,-3.0f, self.frame.size.width, 3.0f);
            shadowImg.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
            shadowImg.tag = shadowTag;
            [self addSubview:shadowImg];
        }
    }
}


@end
