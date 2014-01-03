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

@end


@implementation StatsCounterCell

+ (CGFloat)heightForRow {
    return 90.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.countViews = [[NSMutableArray alloc] init];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5.0f, self.contentView.frame.size.width, 20.0f)];
        titleLabel.font = [WPStyleGuide regularTextFont];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel = titleLabel;
        [self addSubview:titleLabel];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = [UIColor greenColor];
        NSLog(@"contentview frame on init %@", NSStringFromCGRect(self.contentView.frame));
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    if (title.length > 0) {
        self.titleLabel.text = title;
    } else {
        self.titleLabel.frame = (CGRect) {
            .origin = self.titleLabel.frame.origin,
            .size = CGSizeZero
        };
    }
}

- (void)addCount:(NSNumber *)count withLabel:(NSString *)label {
    UIView *countView = [[UIView alloc] initWithFrame:CGRectMake(0, 10.0f, 100.0f, 50.0f)];
    countView.backgroundColor = [UIColor magentaColor];
    UILabel *countNumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 5.0f, countView.frame.size.width, 30.0f)];
    UILabel *countText = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(countNumber.frame), countView.frame.size.width, 16.0f)];
    countNumber.text = [count stringValue];
    countText.text = label;
    countNumber.textAlignment = NSTextAlignmentCenter;
    countText.textAlignment = NSTextAlignmentCenter;
    countNumber.font = [WPStyleGuide postTitleFont];
    countText.font = [WPStyleGuide subtitleFont];

    [countView addSubview:countNumber];
    [countView addSubview:countText];
    
    [self.contentView addSubview:countView];
    [self.countViews addObject:countView];
    
    CGFloat yOffset = CGRectGetMaxY(self.titleLabel.frame) + 5.0f;
    if ([self.countViews count] == 2) {
        __block CGFloat offsetWidth = self.contentView.frame.size.width*0.33;
        [self.countViews enumerateObjectsUsingBlock:^(UIView *v, NSUInteger idx, BOOL *stop) {
            v.frame = (CGRect) {
                .origin = CGPointMake(offsetWidth - v.frame.size.width/2, yOffset),
                .size = v.frame.size
            };
            offsetWidth = self.contentView.frame.size.width*0.66;
        }];
        
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
    self.titleLabel.text = @"";
    self.titleLabel.frame = CGRectMake(0, 5.0f, self.contentView.frame.size.width, 20.0f);
}

@end
