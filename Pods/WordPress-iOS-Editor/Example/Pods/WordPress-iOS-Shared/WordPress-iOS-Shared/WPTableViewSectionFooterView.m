#import "WPTableViewSectionFooterView.h"
#import "WPStyleGuide.h"
#import "NSString+Util.h"

@interface WPTableViewSectionFooterView() {
    UILabel *_titleLabel;
}

@end

CGFloat const WPTableViewSectionFooterViewStandardOffset = 16.0;
CGFloat const WPTableViewSectionFooterViewTopVerticalPadding = 21.0;
CGFloat const WPTableViewSectionFooterViewBottomVerticalPadding = 8.0;


@implementation WPTableViewSectionFooterView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 0;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.font = [WPStyleGuide subtitleFont];
        _titleLabel.textColor = [WPStyleGuide allTAllShadeGrey];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    _titleLabel.text = _title;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize titleSize = [[self class] sizeForTitle:_titleLabel.text andWidth:CGRectGetWidth(self.bounds)];
    _titleLabel.frame = CGRectMake(WPTableViewSectionFooterViewStandardOffset, WPTableViewSectionFooterViewTopVerticalPadding, titleSize.width, titleSize.height);
}

+ (CGFloat)heightForTitle:(NSString *)title andWidth:(CGFloat)width
{
    if ([title length] == 0)
        return 0.0;
    
    return [self sizeForTitle:title andWidth:width].height + WPTableViewSectionFooterViewTopVerticalPadding + WPTableViewSectionFooterViewBottomVerticalPadding;
}

#pragma mark - Private Methods

+ (CGSize)sizeForTitle:(NSString *)title andWidth:(CGFloat)width
{
    CGFloat titleWidth = width - 2 * WPTableViewSectionFooterViewStandardOffset;
    return [title suggestedSizeWithFont:[WPStyleGuide subtitleFont] width:titleWidth];
}


@end
