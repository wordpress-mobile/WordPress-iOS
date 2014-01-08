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
        titleLabel.font = [WPStyleGuide subtitleFont];
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

- (void)setTitle:(NSString *)title {
    UIView *separator = [[UIView alloc] init];
    if (title.length > 0) {
        self.titleLabel.text = [title uppercaseString];
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.textColor = [WPStyleGuide newKidOnTheBlockBlue];
        //self.titleLabel.backgroundColor = [UIColor purpleColor];
        separator.frame = (CGRect) {
            .origin = CGPointMake(CGRectGetMinX(self.titleLabel.frame), CGRectGetMaxY(self.titleLabel.frame)),
            .size = CGSizeMake(self.titleLabel.frame.size.width, IS_RETINA ? 0.5f : 1.0f)
        };
        separator.backgroundColor = [WPStyleGuide newKidOnTheBlockBlue];
    } else {
        self.titleLabel.frame = (CGRect) {
            .origin = self.titleLabel.frame.origin,
            .size = CGSizeZero
        };
        separator.frame = (CGRect) {
            .origin = CGPointMake(CountPadding, 0),
            .size = CGSizeMake(self.contentView.frame.size.width-2*CountPadding, IS_RETINA ? 0.5f : 1.0f)
        };
        separator.backgroundColor = [WPStyleGuide readGrey];
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
    
    CGFloat yOffset = CGRectGetMaxY(self.titleLabel.frame) + 5.0f;
    if ([self.countViews count] == 2) {
        __block CGFloat width = self.contentView.frame.size.width;
//        [self.countViews enumerateObjectsUsingBlock:^(UIView *v, NSUInteger idx, BOOL *stop) {
//            v.frame = (CGRect) {
//                .origin = CGPointMake(offsetWidth - v.frame.size.width/2, yOffset),
//                .size = v.frame.size
//            };
//            offsetWidth = self.contentView.frame.size.width*0.75;
//        }];
        UIView *leftView = self.countViews[0];
        leftView.frame = (CGRect) {
            .origin = CGPointMake(width*0.25 - leftView.frame.size.width/2, yOffset),
            .size = leftView.frame.size
        };
        UIView *separator = [[UIView alloc] init];
        separator.frame = (CGRect) {
            .origin = CGPointMake(width*0.5, CGRectGetMinY(leftView.frame)),
            .size = CGSizeMake(IS_RETINA ? 0.5f : 1.0f, leftView.frame.size.height)
        };
        separator.backgroundColor = [WPStyleGuide readGrey];
        [self.contentView addSubview:separator];
        [self.separatorLines addObject:separator];
        UIView *rightView = self.countViews[1];
        rightView.frame = (CGRect) {
            .origin = CGPointMake(width*0.75 - rightView.frame.size.width/2, yOffset),
            .size = rightView.frame.size
        };
        
    } else {
        countView.frame = (CGRect) {
            .origin = CGPointMake(CGRectGetMidX(self.contentView.frame) - CGRectGetMidX(countView.frame), yOffset),
            .size = countView.frame.size
        };
    }
}

- (void)prepareForReuse {
    [self.countViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.countViews removeAllObjects];
    [self.separatorLines makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.separatorLines = [NSMutableArray array];
    self.titleLabel.text = @"";
    self.titleLabel.frame = CGRectMake(CountPadding, 0, self.contentView.frame.size.width-2*CountPadding, TitleHeight);
}

@end
