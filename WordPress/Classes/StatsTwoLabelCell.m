/*
 * StatsTwoLabelCell.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsTwoLabelCell.h"

@interface StatsTwoLabelCell ()

@property (nonatomic, weak) UIView *separator;

@end


@implementation StatsTwoLabelCell

+ (CGFloat)heightForRow {
    return 30.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setLeft:(NSString *)left right:(NSString *)right {
    [self setLeft:left right:right titleCell:NO];
}

- (void)setLeft:(NSString *)left right:(NSString *)right titleCell:(BOOL)titleCell {
    UILabel *leftLabel = [self createLabelWithTitle:left];
    UILabel *rightLabel = [self createLabelWithTitle:right];
    UIColor *color = titleCell ? [WPStyleGuide newKidOnTheBlockBlue] : [WPStyleGuide whisperGrey];
    leftLabel.textColor = color;
    rightLabel.textColor = color;

    CGFloat yOrigin = ([self.class heightForRow]-leftLabel.frame.size.height)/2;
    rightLabel.frame = (CGRect) {
        .origin = CGPointMake(self.frame.size.width - rightLabel.frame.size.width - 10.0f, yOrigin),
        .size = CGSizeMake(rightLabel.frame.size.width,rightLabel.frame.size.height)
    };
    leftLabel.frame = (CGRect) {
        .origin = CGPointMake(10.0f, yOrigin),
        .size = CGSizeMake(CGRectGetMinX(rightLabel.frame) - 15.0f, leftLabel.frame.size.height)
    };
    [self.contentView addSubview:leftLabel];
    [self.contentView addSubview:rightLabel];
    
    if (!titleCell) {
        UIView *view = [[UIView alloc] initWithFrame:(CGRect) {
            .origin = CGPointMake(CGRectGetMinX(leftLabel.frame), 0),
            .size = CGSizeMake(CGRectGetMaxX(rightLabel.frame) - CGRectGetMinX(leftLabel.frame), IS_RETINA ? 0.5f : 1.0f)
        }];
        view.backgroundColor = [WPStyleGuide readGrey];
        [self addSubview:view];
    }
}

- (UILabel *)createLabelWithTitle:(NSString *)title {
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.backgroundColor = [UIColor whiteColor];
    titleLabel.opaque = YES;
    titleLabel.font = [WPStyleGuide subtitleFont];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [titleLabel sizeToFit];
    return titleLabel;
}

- (void)prepareForReuse {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
