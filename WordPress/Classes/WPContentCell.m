//
//  WPContentCell.m
//  
//
//  Created by Tom Witkin on 12/12/13.
//
//

#import "WPContentCell.h"
#import "WPComLanguages.h"
#import "UIImageView+Gravatar.h"


@interface WPContentCell() {
    UIImageView *_gravatarImageView;
    UILabel *_statusLabel;
    UILabel *_titleLabel;
    UILabel *_detailLabel;
}

@end

@implementation WPContentCell

CGFloat const WPContentCellStandardOffset = 16.0;
CGFloat const WPContentCellTitleAndDetailVerticalOffset = 6.0;
CGFloat const WPContentCellLabelAndTitleHorizontalOffset = -0.5;
CGFloat const WPContentCellAccessoryViewOffset = 25.0;
CGFloat const WPContentCellImageWidth = 48.0;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        _gravatarImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_gravatarImageView];
        
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.backgroundColor = [UIColor clearColor];
        _statusLabel.textAlignment = NSTextAlignmentLeft;
        _statusLabel.numberOfLines = 0;
        _statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _statusLabel.font = [[self class] statusFont];
        _statusLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _statusLabel.textColor = [UIColor colorWithRed:30/255.0f green:140/255.0f blue:190/255.0f alpha:1.0f];
        [self.contentView addSubview:_statusLabel];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 0;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.font = [[self class] titleFont];
        _titleLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _titleLabel.textColor = [WPStyleGuide littleEddieGrey];
        [self.contentView addSubview:_titleLabel];
        
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.backgroundColor = [UIColor clearColor];
        _detailLabel.textAlignment = NSTextAlignmentLeft;
        _detailLabel.numberOfLines = 0;
        _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _detailLabel.font = [[self class] detailFont];
        _detailLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _detailLabel.textColor = [WPStyleGuide allTAllShadeGrey];
        [self.contentView addSubview:_detailLabel];
    }
    return self;
}


- (void)prepareForReuse{
    [super prepareForReuse];
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat maxWidth = CGRectGetWidth(self.bounds);
    
    _gravatarImageView.frame = [[self class] gravatarImageViewFrame];
    _statusLabel.frame = [[self class] statusLabelFrameForContentProvider:self.contentProvider maxWidth:maxWidth];
    _titleLabel.frame = [[self class] titleLabelFrameForContentProvider:self.contentProvider previousFrame:_statusLabel.frame maxWidth:maxWidth];
    _detailLabel.frame = [[self class] detailLabelFrameForContentProvider:self.contentProvider previousFrame:_titleLabel.frame maxWidth:maxWidth];
}

+ (CGFloat)rowHeightForContentProvider:(id<WPContentViewProvider>)contentProvider andWidth:(CGFloat)width;
{
    CGRect gravatarGrame = [[self class] gravatarImageViewFrame];
    CGRect statusFrame = [[self class] statusLabelFrameForContentProvider:contentProvider maxWidth:width];
    CGRect titleFrame = [[self class] titleLabelFrameForContentProvider:contentProvider previousFrame:statusFrame maxWidth:width];
    CGRect detailFrame = [[self class] detailLabelFrameForContentProvider:contentProvider previousFrame:titleFrame maxWidth:width];
    
    return MAX(CGRectGetMaxY(gravatarGrame), CGRectGetMaxY(detailFrame)) + WPContentCellStandardOffset;
}

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider
{
    _contentProvider = contentProvider;
    
    [_gravatarImageView setImageWithGravatarEmail:[contentProvider gravatarEmailForDisplay] fallbackImage:[UIImage imageNamed:@"comment-default-gravatar-image"]];
    
    _titleLabel.text = [[self class] titleTextForContentProvider:contentProvider];
    _statusLabel.text = [[self class] statusTextForContentProvider:contentProvider];
    _statusLabel.textColor = [[self class] statusColorForContentProvider:contentProvider];
    _detailLabel.text = [[self class] detailTextForContentProvider:contentProvider];
    
    if (_titleLabel.text != nil) {
        _titleLabel.attributedText = [[NSAttributedString alloc] initWithString:_titleLabel.text attributes:[[self class] titleAttributes]];
    }
    
    if (_statusLabel.text != nil) {
        _statusLabel.attributedText = [[NSAttributedString alloc] initWithString:_statusLabel.text attributes:[[self class] statusAttributes]];
    }
    
    if (_detailLabel.text != nil) {
        NSRange barRange = [_detailLabel.text rangeOfString:@"|"];
        NSMutableAttributedString *detailText = [[NSMutableAttributedString alloc] initWithString:_detailLabel.text attributes:[[self class] detailAttributes]];
        [detailText addAttribute:NSForegroundColorAttributeName value:[WPStyleGuide readGrey] range:barRange];
        _detailLabel.attributedText = detailText;
    }
}

+ (BOOL)showGravatarImage {
    return NO;
}

+ (UIFont *)statusFont
{
    return [WPStyleGuide labelFont];
}

+ (NSDictionary *)statusAttributes
{
    return [WPStyleGuide labelAttributes];
}

+ (NSString *)statusTextForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    return [[contentProvider statusForDisplay] uppercaseString];
}

+ (UIColor *)statusColorForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    return [WPStyleGuide jazzyOrange];
}

+ (UIFont *)titleFont
{
    return [UIFont fontWithName:@"OpenSans" size:18.0];
}

+ (NSDictionary *)titleAttributes
{
    return [WPStyleGuide postTitleAttributes];
}

+ (NSString *)titleTextForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    return [contentProvider titleForDisplay];
}

+ (UIFont *)detailFont
{
    return [WPStyleGuide subtitleFont];
}

+ (NSDictionary *)detailAttributes
{
    return [WPStyleGuide subtitleAttributes];
}

+ (NSString *)detailTextForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    static NSDateFormatter *dateFormatter = nil;
    
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd '|' HH:mm a"];
    }
    
    NSDate *date = [contentProvider dateForDisplay];
    return [dateFormatter stringFromDate:date];
}


#pragma mark - Private Methods

+ (CGFloat)textWidth:(CGFloat)maxWidth
{
    CGFloat imageWidth = [[self class] showGravatarImage] ? WPContentCellImageWidth + WPContentCellStandardOffset : 0.0;
    return maxWidth - WPContentCellStandardOffset - WPContentCellAccessoryViewOffset - imageWidth;
}

+ (CGFloat)textXOrigin {
    CGFloat x = WPContentCellStandardOffset;
    x += [[self class] showGravatarImage] ? WPContentCellStandardOffset + WPContentCellImageWidth : 0.0;
    x += IS_RETINA ? -0.5 : 0.0;
    return x;
}

+ (CGRect)gravatarImageViewFrame {
    return [[self class] showGravatarImage] ? CGRectMake(WPContentCellStandardOffset, WPContentCellStandardOffset, WPContentCellImageWidth, WPContentCellImageWidth) : CGRectZero;
}

+ (CGRect)statusLabelFrameForContentProvider:(id<WPContentViewProvider>)contentProvider maxWidth:(CGFloat)maxWidth
{
    NSString *statusText = [self statusTextForContentProvider:contentProvider];
    if ([statusText length] != 0) {
        CGSize size;
        size = [statusText boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] statusAttributes] context:nil].size;
            return CGRectMake([[self class] textXOrigin], WPContentCellStandardOffset, size.width, size.height);
    } else {
        return CGRectMake(0, WPContentCellStandardOffset, 0, 0);
    }
}

+ (CGRect)titleLabelFrameForContentProvider:(id<WPContentViewProvider>)contentProvider previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
    CGSize size;
    size = [[[self class] titleTextForContentProvider:contentProvider] boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] titleAttributes] context:nil].size;
    
    CGFloat offset = 0.0;
    if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
        offset = WPContentCellTitleAndDetailVerticalOffset;
    }
    
    return CGRectMake([[self class] textXOrigin], CGRectGetMaxY(previousFrame) + offset, size.width, size.height);
}

+ (CGRect)detailLabelFrameForContentProvider:(id<WPContentViewProvider>)contentProvider previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
    CGSize size;
    size = [[[self class] detailTextForContentProvider:contentProvider] boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] detailAttributes] context:nil].size;
    
    CGFloat offset = 0.0;
    if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
        offset = WPContentCellTitleAndDetailVerticalOffset;
    }
    
    return CGRectIntegral(CGRectMake([[self class] textXOrigin], CGRectGetMaxY(previousFrame) + offset, size.width, size.height));
}

@end
