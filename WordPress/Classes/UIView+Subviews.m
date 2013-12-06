//
//  UIView+Subviews.m
//  WordPress
//
//  Created by Tom Witkin on 12/6/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "UIView+Subviews.h"

@implementation UIView (Subviews)

- (void)addSubviewWithFadeAnimation:(UIView *)subview {
    
    CGFloat finalAlpha = subview.alpha;
    
    subview.alpha = 0.0;
    [self addSubview:subview];
    [UIView animateWithDuration:0.2 animations:^{
        subview.alpha = finalAlpha;
    }];
}

@end
