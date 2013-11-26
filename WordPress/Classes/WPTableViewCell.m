//
//  WPTableViewCell.m
//  WordPress
//
//  Created by Michael Johnston on 11/9/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPTableViewCell.h"

CGFloat const WPTableViewFixedWidth = 500;

@implementation WPTableViewCell

- (void)setFrame:(CGRect)frame {
    // On iPad, add a margin around tables
    if (IS_IPAD) {
        frame.origin.x = (self.superview.frame.size.width - WPTableViewFixedWidth) / 2;
        frame.size.width = WPTableViewFixedWidth;
    }
    [super setFrame:frame];
}

@end
