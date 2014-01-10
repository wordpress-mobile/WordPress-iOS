/*
 * StatsTwoLabelCell.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsTwoLabelCell.h"
#import "StatsTopPost.h"
#import "StatsClickGroup.h"
#import "StatsClick.h"
#import "StatsReferrerGroup.h"
#import "StatsReferrer.h"
#import "StatsViewByCountry.h"
#import "StatsTitleCountItem.h"
#import "WPImageSource.h"
#import "NSString+XMLExtensions.h"

static CGFloat const CellHeight = 30.0f;
static CGFloat const PaddingForCellSides = 10.0f;
static CGFloat const PaddingBetweenLeftAndRightLabels = 15.0f;
static CGFloat const PaddingImageText = 10.0f;
static CGFloat const ImageSize = 20.0f;

@interface StatsTwoLabelCell ()

@property (nonatomic, weak) UIView *separator;
@property (nonatomic, weak) UIView *leftView;
@property (nonatomic, weak) UIView *rightView;

@end


@implementation StatsTwoLabelCell

+ (CGFloat)heightForRow {
    return CellHeight;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat yOrigin = [self yValueToCenterViewVertically:self.rightView];
    self.rightView.frame = (CGRect) {
        .origin = CGPointMake(self.frame.size.width - self.rightView.frame.size.width - PaddingForCellSides, yOrigin),
        .size = self.rightView.frame.size
    };

    yOrigin = [self yValueToCenterViewVertically:self.leftView];
    self.leftView.frame = (CGRect) {
        .origin = CGPointMake(PaddingForCellSides, yOrigin),
        .size = CGSizeMake(CGRectGetMinX(self.rightView.frame) - PaddingBetweenLeftAndRightLabels, self.leftView.frame.size.height)
    };
    
    if (self.separator) {
        self.separator.frame = (CGRect) {
            .origin = CGPointMake(CGRectGetMinX(self.leftView.frame), 0),
            .size = CGSizeMake(CGRectGetMaxX(self.rightView.frame) - CGRectGetMinX(self.leftView.frame), IS_RETINA ? 0.5f : 1.0f)
        };
    }
}

- (NSNumberFormatter *)numberFormatter {
    if (_numberFormatter) {
        return _numberFormatter;
    }
    _numberFormatter = [[NSNumberFormatter alloc]init];
    _numberFormatter.locale = [NSLocale currentLocale];
    _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    _numberFormatter.usesGroupingSeparator = YES;
    return _numberFormatter;
}

- (void)insertData:(StatsTitleCountItem *)cellData {
    self.cellData = cellData;
    
    NSString *left = [cellData.title stringByDecodingXMLCharacters];
    NSString *right = [self.numberFormatter stringFromNumber:cellData.count];
    if ([cellData isKindOfClass:[StatsViewByCountry class]]) {
        [self setLeft:left withImageUrl:[(StatsViewByCountry *)cellData imageUrl] right:right titleCell:NO];
    } else if ([cellData isKindOfClass:[StatsGroup class]]) {
        [self setLeft:left withImageUrl:[(StatsGroup *)cellData iconUrl] right:right titleCell:NO];
    } else {
        [self setLeft:left withImageUrl:nil right:right titleCell:NO];
    }
}

- (void)setLeft:(NSString *)left withImageUrl:(NSURL *)imageUrl right:(NSString *)right titleCell:(BOOL)titleCell {
    UIView *leftView;
    BOOL shouldShowImage = ([self.cellData isKindOfClass:[StatsViewByCountry class]] || [self.cellData isKindOfClass:[StatsGroup class]]);
    if (shouldShowImage) {
        leftView = [self createLeftViewWithTitle:left imageUrl:imageUrl titleCell:titleCell];
    } else {
        leftView = [self createLabelWithTitle:left titleCell:titleCell];
    }
    UIView *rightView = [self createLabelWithTitle:right titleCell:titleCell];
    self.leftView = leftView;
    self.rightView = rightView;
    [self.rightView sizeToFit];
    [self.leftView sizeToFit];
    [self.contentView addSubview:self.leftView];
    [self.contentView addSubview:self.rightView];
    
    [self layoutSubviews];
    
    if (!titleCell) {
        UIView *separator = [[UIView alloc] initWithFrame:(CGRect) {
            .origin = CGPointMake(CGRectGetMinX(self.leftView.frame), 0),
            .size = CGSizeMake(CGRectGetMaxX(self.rightView.frame) - CGRectGetMinX(self.leftView.frame), IS_RETINA ? 0.5f : 1.0f)
        }];
        separator.backgroundColor = [WPStyleGuide readGrey];
        self.separator = separator;
        [self addSubview:separator];
    }
}

- (UILabel *)createLabelWithTitle:(NSString *)title titleCell:(BOOL)titleCell {
    UIColor *color = titleCell ? [WPStyleGuide newKidOnTheBlockBlue] : [WPStyleGuide whisperGrey];
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textColor = color;
    titleLabel.text = title;
    titleLabel.backgroundColor = [UIColor whiteColor];
    titleLabel.opaque = YES;
    titleLabel.font = [WPStyleGuide subtitleFont];
    [titleLabel sizeToFit];
    return titleLabel;
}

- (UIView *)createLeftViewWithTitle:(NSString *)title imageUrl:(NSURL *)imageUrl titleCell:(BOOL)titleCell {
    
    UILabel *label = [self createLabelWithTitle:title titleCell:titleCell];
    [label sizeToFit];
    UIView *view = [[UIView alloc] init];

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(0, 0, 20 , 20);
    
    if (imageUrl != nil) {
        [[WPImageSource sharedSource] downloadImageForURL:imageUrl withSuccess:^(UIImage *image) {
            imageView.image = image;
        } failure:^(NSError *error) {
            DDLogWarn(@"Unable to download icon %@", error);
        }];
    }
    
    label.frame = (CGRect) {
        .origin = CGPointMake(ImageSize + PaddingImageText, 0),
        .size = label.frame.size
    };
    
    [view addSubview:imageView];
    [view addSubview:label];
    
    view.frame = (CGRect) {
        .origin = CGPointZero,
        .size = CGSizeMake(CGRectGetMaxX(label.frame), 20)
    };
    return view;
}

- (void)prepareForReuse {
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (CGFloat)yValueToCenterViewVertically:(UIView *)view {
    return ([self.class heightForRow] - view.frame.size.height)/2;
}

@end
