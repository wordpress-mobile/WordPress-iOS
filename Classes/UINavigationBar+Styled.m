//
//  UINavigationBar+Styled.m
//  WordPress
//
//  Created by Eric Johnson on 7/3/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UINavigationBar+Styled.h"

@implementation UINavigationBar (Styled)

- (void)drawRect:(CGRect)rect {
    // If iOS 5 then rely on the UIAppearance instead of category smashing.
    if ([[self class] respondsToSelector:@selector(appearance)]) {
        [super drawRect:rect];
        return;
    }
    
    UIImage *img = [UIImage imageNamed:@"navbar_background"];
    [img drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
}

@end
