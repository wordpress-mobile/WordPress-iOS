/*
 * StatsButtonCell.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsButtonCell.h"
#import "WPStyleGuide.h"

@implementation StatsButtonCell

+ (CGFloat)heightForRow {
    return 44.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)addButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide baseDarkerBlue] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide allTAllShadeGrey] forState:UIControlStateHighlighted];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    UIButton *previousButton = [self.contentView.subviews lastObject];
    if (previousButton) {
        button.frame = (CGRect) {
            .origin = CGPointMake(CGRectGetMaxX(previousButton.frame) + 5.0f, previousButton.frame.origin.y),
            .size = button.frame.size
        };
    }
    [self.contentView addSubview:button];
}

- (void)prepareForReuse {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
