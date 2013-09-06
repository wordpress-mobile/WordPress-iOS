//
//  WPTableViewSectionTitleView.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 9/5/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPTableViewSectionTitleView.h"

@interface WPTableViewSectionTitleView() {
    UILabel *_titleLabel;
}

@end

@implementation WPTableViewSectionTitleView

CGFloat const WPTableViewSectionTitleViewStandardOffset = 16.0;
CGFloat const WPTableViewSectionTitleViewTopVerticalPadding = 21.0;
CGFloat const WPTableViewSectionTitleViewBottomVerticalPadding = 8.0;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 0;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.font = [WPStyleGuide tableviewSectionHeaderFont];
        _titleLabel.textColor = [WPStyleGuide whisperGrey];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    _title = [title uppercaseString];
    _titleLabel.text = _title;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize titleSize = [[self class] sizeForTitle:_titleLabel.text andWidth:CGRectGetWidth(self.bounds)];
    _titleLabel.frame = CGRectMake(WPTableViewSectionTitleViewStandardOffset, WPTableViewSectionTitleViewTopVerticalPadding, titleSize.width, titleSize.height);
}

+ (CGFloat)heightForTitle:(NSString *)title andWidth:(CGFloat)width
{
    if ([title length] == 0)
        return 0.0;
    
    return [self sizeForTitle:title andWidth:width].height + WPTableViewSectionTitleViewTopVerticalPadding + WPTableViewSectionTitleViewBottomVerticalPadding;
}

#pragma mark - Private Methods

+ (CGSize)sizeForTitle:(NSString *)title andWidth:(CGFloat)width
{
    return [title sizeWithFont:[WPStyleGuide tableviewSectionHeaderFont] constrainedToSize:CGSizeMake(width - 2 * WPTableViewSectionTitleViewStandardOffset, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
}


@end
