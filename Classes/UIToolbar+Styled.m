//
//  UIToolbar+Styled.m
//  WordPress
//
//  Created by Eric Johnson on 7/3/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UIToolbar+Styled.h"
#import "UIColor+Helpers.h"

@implementation UIToolbar (Styled)

- (void)drawRect:(CGRect)rect {
    // If iOS 5 then rely on the UIAppearance instead of category smashing.
    if ([[self class] respondsToSelector:@selector(appearance)]) {
        [super drawRect:rect];
        return;
    }
    
    UIImage *img = [UIImage imageNamed:@"toolbar_background"];
    [img drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
}


@end
