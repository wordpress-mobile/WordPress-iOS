//
//  ViewAdminButton.m
//  WordPress
//
//  Created by Jorge Bernal on 7/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ViewAdminButton.h"

@implementation ViewAdminButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setImage:[UIImage imageNamed:@"sidebar_dashboard"] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:@"sidebar_dashboard"] forState:UIControlStateHighlighted];
        [self setBackgroundImage:[[UIImage imageNamed:@"sidebar_cell_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1] forState:UIControlStateNormal];
        [self setBackgroundImage:[[UIImage imageNamed:@"sidebar_cell_bg_selected"] stretchableImageWithLeftCapWidth:0 topCapHeight:1] forState:UIControlStateHighlighted];
        [self setTitleColor:[UIColor colorWithRed:221.0f/255.0f green:221.0f/255.0f blue:221.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];

        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.shadowOffset = CGSizeMake(0, 1.1f);
        self.titleLabel.shadowColor = [UIColor blackColor];
        self.titleLabel.font = [UIFont systemFontOfSize:17.0];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat padding = 8.f;

    CGRect imageFrame = self.imageView.frame;
    imageFrame.origin.x = padding;
    self.imageView.frame = imageFrame;
    CGRect titleFrame = self.titleLabel.frame;
    titleFrame.origin.x = CGRectGetMaxX(imageFrame) + padding;
    titleFrame.size.width = CGRectGetMaxX(self.bounds) - titleFrame.origin.x - padding;
    self.titleLabel.frame = titleFrame;
}

@end
