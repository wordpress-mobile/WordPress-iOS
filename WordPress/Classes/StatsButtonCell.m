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

static CGFloat const StatsButtonHeight = 30.0f;

@implementation StatsButtonCell

+ (CGFloat)heightForRow {
    return StatsButtonHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.buttons = [NSMutableArray array];
        _currentActiveButton = 0;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat widthPerButton = self.frame.size.width/self.buttons.count;
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *b, NSUInteger idx, BOOL *stop)
    {
        b.frame = (CGRect) {
            .origin = CGPointMake(widthPerButton*idx, 0),
            .size = CGSizeMake(widthPerButton, StatsButtonHeight)
        };
    }];
    
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *obj, NSUInteger idx, BOOL *stop) {
        if (idx == _currentActiveButton) {
            [obj setBackgroundColor:[WPStyleGuide newKidOnTheBlockBlue]];
        } else {
            [obj setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
        }
    }];
}

- (void)addButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action section:(StatsSection)section {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title.uppercaseString forState:UIControlStateNormal];
    button.titleLabel.font = [WPStyleGuide subtitleFont];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
    [button addTarget:self action:@selector(activateButton:) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    button.tag = section;

    [self.buttons addObject:button];
    [self.contentView addSubview:button];
}

- (void)activateButton:(UIButton *)sender {
    _currentActiveButton = [self.buttons indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return obj == sender;
    }];
}

- (void)prepareForReuse {
    self.buttons = [NSMutableArray array];
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
