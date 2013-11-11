//
//  WPTableViewCell.m
//  WordPress
//
//  Created by Michael Johnston on 11/9/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPTableViewCell.h"

CGFloat const TableViewCellMarginPercentage = 0.2;

@implementation WPTableViewCell

- (void)setFrame:(CGRect)frame {
    // On iPad, add a margin around tables
    if (IS_IPAD) {
        CGFloat inset = self.superview.frame.size.width * TableViewCellMarginPercentage;
        frame.origin.x = inset;
        frame.size.width = self.superview.frame.size.width - 2 * inset;
    }
    [super setFrame:frame];
}

@end
