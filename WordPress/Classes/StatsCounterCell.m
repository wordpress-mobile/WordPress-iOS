/*
 * StatsCounterCell.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsCounterCell.h"

@interface StatsCounterCell ()

@property (nonatomic, strong) NSMutableArray *countViews;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, strong) NSMutableArray *separatorLines;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@end

static CGFloat const StatCountViewWidth = 150.0f;
static CGFloat const StatCountNumberHeight = 35.0f;
static CGFloat const StatCountTextHeight = 25.0f;
static CGFloat const CountPadding = 10.0f;
static CGFloat const TitleHeight = 20.0f;
static CGFloat const StatCounterCellHeight = 100.0f;

@implementation StatsCounterCell

+ (CGFloat)heightForRow {
    return StatCounterCellHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.countViews = [[NSMutableArray alloc] init];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CountPadding, 0, self.contentView.frame.size.width-2*CountPadding, TitleHeight)];
        titleLabel.font = [WPStyleGuide subtitleFontBold];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel = titleLabel;
        [self addSubview:titleLabel];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.numberFormatter = [[NSNumberFormatter alloc]init];
        self.numberFormatter.locale = [NSLocale currentLocale];
        self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        self.numberFormatter.usesGroupingSeparator = YES;
        self.separatorLines = [NSMutableArray array];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIView *topSeparator = (UIView *)self.separatorLines[0];
    if (self.titleLabel.text.length > 0) {
        topSeparator.frame = (CGRect) {
            .origin = CGPointMake(CGRectGetMinX(self.titleLabel.frame), CGRectGetMaxY(self.titleLabel.frame)),
            .size = CGSizeMake(self.contentView.frame.size.width-2*CountPadding, IS_RETINA ? 0.5f : 1.0f)
        };
        topSeparator.backgroundColor = [WPStyleGuide newKidOnTheBlockBlue];
    } else {
        self.titleLabel.frame = (CGRect) {
            .origin = self.titleLabel.frame.origin,
            .size = CGSizeZero
        };
        topSeparator.frame = (CGRect) {
            .origin = CGPointMake(CountPadding, 0),
            .size = CGSizeMake(self.contentView.frame.size.width-2*CountPadding, IS_RETINA ? 0.5f : 1.0f)
        };
        topSeparator.backgroundColor = [WPStyleGuide readGrey];
    }

    CGFloat yOffset = CGRectGetMaxY(self.titleLabel.frame) + 10.0f;
    if (self.countViews.count == 1) {
        UIView *countView = self.countViews[0];
        countView.center = CGPointMake(self.frame.size.width/2, yOffset+CGRectGetMidY(countView.bounds));
    } else if ([self.countViews count] == 2) {
        CGFloat width = self.contentView.frame.size.width;
        UIView *leftView = self.countViews[0];
        leftView.frame = (CGRect) {
            .origin = CGPointMake(width*0.25 - leftView.frame.size.width/2, yOffset),
            .size = leftView.frame.size
        };
        UIView *rightView = self.countViews[1];
        rightView.frame = (CGRect) {
            .origin = CGPointMake(width*0.75 - rightView.frame.size.width/2, yOffset),
            .size = rightView.frame.size
        };
        if (self.separatorLines.count > 1) {
            UIView *separator = (UIView *)self.separatorLines[1];
            separator.frame = (CGRect) {
                .origin = CGPointMake(width*0.5, CGRectGetMinY(leftView.frame)),
                .size = CGSizeMake(IS_RETINA ? 0.5f : 1.0f, leftView.frame.size.height)
            };
            separator.backgroundColor = [WPStyleGuide readGrey];
        }
    }
}

- (void)setTitle:(NSString *)title {
    UIView *separator = [[UIView alloc] init];
    if (title.length > 0) {
        self.titleLabel.text = [title uppercaseString];
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.textColor = [WPStyleGuide newKidOnTheBlockBlue];
    }
    [self.separatorLines addObject:separator];
    [self addSubview:separator];
}

- (void)addCount:(NSNumber *)count withLabel:(NSString *)label {
    UIView *countView = [[UIView alloc] initWithFrame:CGRectMake(0, CountPadding, StatCountViewWidth, StatCountNumberHeight + StatCountTextHeight)];
    UILabel *countNumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, countView.frame.size.width, StatCountNumberHeight)];
    UILabel *countText = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(countNumber.frame), countView.frame.size.width, StatCountTextHeight)];
    
    countNumber.text = [self.numberFormatter stringFromNumber:count];
    countNumber.textAlignment = NSTextAlignmentCenter;
    countNumber.textColor = [WPStyleGuide whisperGrey];
    countNumber.font = [WPStyleGuide largePostTitleFont];

    countText.text = label;
    countText.textAlignment = NSTextAlignmentCenter;
    countText.textColor = [WPStyleGuide whisperGrey];
    countText.font = [WPStyleGuide tableviewSubtitleFont];

    [countView addSubview:countNumber];
    [countView addSubview:countText];
    
    [self.contentView addSubview:countView];
    [self.countViews addObject:countView];
    
    if (self.countViews.count == 2) {
        UIView *separator = [[UIView alloc] init];
        [self.separatorLines addObject:separator];
        [self.contentView addSubview:separator];
    }
}

- (void)prepareForReuse {
    [self.countViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.countViews = [NSMutableArray array];
    [self.separatorLines makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.separatorLines = [NSMutableArray array];
    self.titleLabel.text = @"";
    self.titleLabel.frame = CGRectMake(CountPadding, 0, self.contentView.frame.size.width-2*CountPadding, TitleHeight);
}

@end
