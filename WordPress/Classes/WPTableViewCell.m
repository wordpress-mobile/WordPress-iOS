//
//  WPTableViewCell.m
//  WordPress
//
//  Created by Michael Johnston on 11/9/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPTableViewCell.h"

CGFloat const WPTableViewFixedWidth = 600;

@implementation WPTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setClipsToBounds:YES];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    CGFloat width = self.superview.frame.size.width;
    // On iPad, add a margin around tables
    if (IS_IPAD && width > WPTableViewFixedWidth) {
        frame.origin.x = (width - WPTableViewFixedWidth) / 2;
        frame.size.width = WPTableViewFixedWidth;
    }
    [super setFrame:frame];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Need to set the origin again on iPad (for margins)
    CGFloat width = self.superview.frame.size.width;
    if (IS_IPAD && width > WPTableViewFixedWidth) {
        CGRect frame = self.frame;
        frame.origin.x = (width - WPTableViewFixedWidth) / 2;
        self.frame = frame;
    }
}

@end
