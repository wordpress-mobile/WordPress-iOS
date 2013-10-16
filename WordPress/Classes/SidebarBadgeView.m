//
//  SidebarBadgeView.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 6/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "SidebarBadgeView.h"
#import <QuartzCore/QuartzCore.h>

@interface SidebarBadgeView() {
    UILabel *_badgeCountLabel;
}

@end

@implementation SidebarBadgeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initializeBadgeView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeBadgeView];
    }
    return self;
}

- (void)setBadgeCount:(NSUInteger)badgeCount
{
    _badgeCountLabel.text = [NSString stringWithFormat:@"%d", badgeCount];
    [self invalidateIntrinsicContentSize];
}

- (void)setBadgeColor:(SidebarBadgeViewBadgeColor)badgeColor
{
    if (_badgeColor != badgeColor) {
        _badgeColor = badgeColor;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.badgeColor == SidebarBadgeViewBadgeColorOrange) {
        self.backgroundColor = [UIColor UIColorFromHex:0xD54E21];
    } else {
        self.backgroundColor = [UIColor UIColorFromHex:0x2EA2CC];
    }
    
    CGSize textSize = [_badgeCountLabel.text sizeWithFont:_badgeCountLabel.font];
    CGFloat x = (CGRectGetWidth(self.bounds) - textSize.width)/2.0;
    CGFloat y = (CGRectGetHeight(self.bounds) - textSize.height)/2.0;
    _badgeCountLabel.frame = CGRectIntegral(CGRectMake(x, y, textSize.width, textSize.height));

    self.layer.cornerRadius = CGRectGetHeight(self.frame)/2.0;
}

- (void)sizeToFit
{
    CGSize textSize = [_badgeCountLabel.text sizeWithFont:_badgeCountLabel.font];
    CGRect frame = CGRectMake(0, 0, textSize.width, textSize.height);
    frame.size.height += 5.0;
    frame.size.width = textSize.width + 14.0;
    self.layer.cornerRadius = CGRectGetHeight(frame)/2.0;
    self.frame = frame;
    
    [self setNeedsLayout];
}

- (CGSize)intrinsicContentSize
{
    CGSize textSize = [_badgeCountLabel.text sizeWithFont:_badgeCountLabel.font];
    CGRect frame = CGRectMake(0, 0, textSize.width, textSize.height);
    frame.size.height += 5.0;
    frame.size.width = textSize.width + 14.0;
    return frame.size;
}

- (void)initializeBadgeView
{
    self.layer.cornerRadius = 9.0;
    _badgeCountLabel = [[UILabel alloc] init];
    _badgeCountLabel.textAlignment = NSTextAlignmentCenter;
    _badgeCountLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10.0];
    _badgeCountLabel.backgroundColor = [UIColor clearColor];
    _badgeCountLabel.numberOfLines = 1;
    _badgeCountLabel.textColor = [UIColor UIColorFromHex:0xffffff alpha:0.65];
    _badgeCountLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _badgeCountLabel.shadowOffset = CGSizeMake(0.0, 0.0);
    [self addSubview:_badgeCountLabel];
}

@end


