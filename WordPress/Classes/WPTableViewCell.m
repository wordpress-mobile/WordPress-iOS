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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        //any further customization
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
    
    //tweak to fix alignment for "Add a site" with UITableViewCellStyleSubtitle
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, self.frame.size.width, self.textLabel.frame.size.height);
    self.detailTextLabel.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y, self.frame.size.width, self.detailTextLabel.frame.size.height);

    // Need to set the origin again on iPad (for margins)
    CGFloat width = self.superview.frame.size.width;
    if (IS_IPAD && width > WPTableViewFixedWidth) {
        CGRect frame = self.frame;
        frame.origin.x = (width - WPTableViewFixedWidth) / 2;
        self.frame = frame;
    }
}

@end
