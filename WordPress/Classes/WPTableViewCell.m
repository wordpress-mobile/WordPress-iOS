//
//  WPTableViewCell.m
//  WordPress
//
//  Created by Michael Johnston on 11/9/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPTableViewCell.h"

@implementation WPTableViewCell

- (void)setFrame:(CGRect)frame {
    CGFloat inset = self.superview.frame.size.width * 0.2;
    frame.origin.x = inset;
    frame.size.width = self.superview.frame.size.width - 2 * inset;
    [super setFrame:frame];
}
@end
