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
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.frame.size.width;
    CGFloat widthPerButton = width/self.buttons.count;
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *b, NSUInteger idx, BOOL *stop)
     {
         b.frame = (CGRect) {
             .origin = CGPointMake(widthPerButton*idx, 0),
             .size = CGSizeMake(widthPerButton, StatsButtonHeight)
         };
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
    
    [self.buttons[0] setBackgroundColor:[WPStyleGuide newKidOnTheBlockBlue]];
    [self.contentView addSubview:button];
}

- (void)setTodayActive:(BOOL)todayActive {
    if (todayActive) {
        [self activateButton:self.buttons[0]];
    }
}

- (void)activateButton:(UIButton *)button {
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *b, NSUInteger idx, BOOL *stop) {
        if (b == button) {
            [b setBackgroundColor:[WPStyleGuide newKidOnTheBlockBlue]];
        } else {
            [b setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
        }
    }];
}

- (void)prepareForReuse {
    self.buttons = [NSMutableArray array];
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
