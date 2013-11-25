//
//  WPTableViewSectionHeaderView.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 9/5/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPTableViewSectionHeaderView.h"

@interface WPTableViewSectionHeaderView() {
    UILabel *_titleLabel;
}

@end

@implementation WPTableViewSectionHeaderView

CGFloat const WPTableViewSectionHeaderViewStandardOffset = 16.0;
CGFloat const WPTableViewSectionHeaderViewTopVerticalPadding = 21.0;
CGFloat const WPTableViewSectionHeaderViewBottomVerticalPadding = 8.0;

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
        
        self.leftMarginPercent =  IS_IPAD ? 0.2 : 0;
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
    
    CGFloat leftMargin = self.superview.frame.size.width * self.leftMarginPercent;
    CGSize titleSize = [[self class] sizeForTitle:_titleLabel.text andWidth:CGRectGetWidth(self.bounds)];
    _titleLabel.frame = CGRectMake(WPTableViewSectionHeaderViewStandardOffset + leftMargin, WPTableViewSectionHeaderViewTopVerticalPadding, titleSize.width, titleSize.height);
}

+ (CGFloat)heightForTitle:(NSString *)title andWidth:(CGFloat)width
{
    if ([title length] == 0)
        return 0.0;
    
    return [self sizeForTitle:title andWidth:width].height + WPTableViewSectionHeaderViewTopVerticalPadding + WPTableViewSectionHeaderViewBottomVerticalPadding;
}

#pragma mark - Private Methods

+ (CGSize)sizeForTitle:(NSString *)title andWidth:(CGFloat)width
{
    CGFloat titleWidth = width - 2 * WPTableViewSectionHeaderViewStandardOffset;
    return [title suggestedSizeWithFont:[WPStyleGuide tableviewSectionHeaderFont] width:titleWidth];
}

@end
