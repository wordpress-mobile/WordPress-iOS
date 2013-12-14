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
#import "NSDate+StringFormatting.h"

@interface WPContentCell() {
    UIImageView *_gravatarImageView;
    UILabel *_statusLabel;
    UILabel *_titleLabel;
    UILabel *_detailLabel;
    UIImageView *_unreadView;
}
@end

@implementation WPContentCell

CGFloat const WPContentCellStandardOffset = 10.0;
CGFloat const WPContentCellStandardiPadOffset = 16.0;
CGFloat const WPContentCellTitleAndDetailVerticalOffset = 4.0;
CGFloat const WPContentCellLabelAndTitleHorizontalOffset = -0.5;
CGFloat const WPContentCellAccessoryViewOffset = 25.0;
CGFloat const WPContentCellImageWidth = 70.0;
CGFloat const WPContentCellTitleNumberOfLines = 3;
CGFloat const WPContentCellUnreadViewSide = 7.0;

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
        _titleLabel.numberOfLines = WPContentCellTitleNumberOfLines;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.font = [[self class] titleFont];
        _titleLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _titleLabel.textColor = [WPStyleGuide littleEddieGrey];
        [self.contentView addSubview:_titleLabel];
        
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.backgroundColor = [UIColor clearColor];
        _detailLabel.textAlignment = NSTextAlignmentLeft;
        _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _detailLabel.font = [[self class] detailFont];
        _detailLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _detailLabel.textColor = [WPStyleGuide allTAllShadeGrey];
        [self.contentView addSubview:_detailLabel];
        
        if ([[self class] supportsUnreadStatus]) {
            _unreadView = [[UIImageView alloc] init];
            
            // create circular image
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(WPContentCellUnreadViewSide, WPContentCellUnreadViewSide), NO, 0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextAddPath(context, [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, WPContentCellUnreadViewSide, WPContentCellUnreadViewSide)] CGPath]);
            CGContextSetFillColorWithColor(context, [WPStyleGuide newKidOnTheBlockBlue].CGColor);
            CGContextFillPath(context);
            _unreadView.image = UIGraphicsGetImageFromCurrentImageContext();
            
            [self.contentView addSubview:_unreadView];
        }
    }
    return self;
}


- (void)prepareForReuse{
    [super prepareForReuse];
    _gravatarImageView.image = nil;
    _unreadView.hidden = YES;
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat maxWidth = CGRectGetWidth(self.bounds);
    
    _gravatarImageView.frame = [[self class] gravatarImageViewFrame];
    
    CGRect statusFrame = [[self class] statusLabelFrameForContentProvider:self.contentProvider maxWidth:maxWidth];
    CGRect titleFrame = [[self class] titleLabelFrameForContentProvider:self.contentProvider previousFrame:statusFrame maxWidth:maxWidth];
    CGRect detailFrame = [[self class] detailLabelFrameForContentProvider:self.contentProvider previousFrame:titleFrame maxWidth:maxWidth];
    
    // Center title and detail frame if Gravatar is shown
    if ([[self class] showGravatarImage] && CGRectGetMaxY(detailFrame) < CGRectGetMaxY(_gravatarImageView.frame)) {
        CGFloat heightOfControls = CGRectGetMaxY(detailFrame) - CGRectGetMinY(statusFrame);
        CGFloat startingYForCenteredControls = floorf((CGRectGetHeight(_gravatarImageView.frame) - heightOfControls)/2.0) + CGRectGetMinY(_gravatarImageView.frame);
        CGFloat offsetToCenter = MIN(CGRectGetMinY(statusFrame) - startingYForCenteredControls, 0);
        
        statusFrame.origin.y -= offsetToCenter;
        titleFrame.origin.y -= offsetToCenter;
        detailFrame.origin.y -= offsetToCenter;
    }
    
    _statusLabel.frame = statusFrame;
    _titleLabel.frame = titleFrame;
    _detailLabel.frame = detailFrame;
    
    _unreadView.frame = [[self class] unreadFrameForHeight:CGRectGetHeight(self.bounds)];
}

+ (CGFloat)rowHeightForContentProvider:(id<WPContentViewProvider>)contentProvider andWidth:(CGFloat)width;
{
    CGRect gravatarFrame = [[self class] gravatarImageViewFrame];
    CGRect statusFrame = [[self class] statusLabelFrameForContentProvider:contentProvider maxWidth:width];
    CGRect titleFrame = [[self class] titleLabelFrameForContentProvider:contentProvider previousFrame:statusFrame maxWidth:width];
    CGRect detailFrame = [[self class] detailLabelFrameForContentProvider:contentProvider previousFrame:titleFrame maxWidth:width];
    
    return MAX(CGRectGetMaxY(gravatarFrame), CGRectGetMaxY(detailFrame)) + [[self class] standardOffset];
}

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider
{
    _contentProvider = contentProvider;
    
    [self setGravatarImageForContentProvider:contentProvider];
    
    _titleLabel.attributedText = [[self class] titleAttributedTextForContentProvider:contentProvider];
    _statusLabel.text = [[self class] statusTextForContentProvider:contentProvider];
    _statusLabel.textColor = [[self class] statusColorForContentProvider:contentProvider];
    _detailLabel.text = [[self class] detailTextForContentProvider:contentProvider];
    
    if (_statusLabel.text != nil) {
        _statusLabel.attributedText = [[NSAttributedString alloc] initWithString:_statusLabel.text attributes:[[self class] statusAttributes]];
        _titleLabel.numberOfLines = WPContentCellTitleNumberOfLines - 1;
    }
    
    if (_detailLabel.text != nil) {
        NSRange barRange = [_detailLabel.text rangeOfString:@"|"];
        NSMutableAttributedString *detailText = [[NSMutableAttributedString alloc] initWithString:_detailLabel.text attributes:[[self class] detailAttributes]];
        [detailText addAttribute:NSForegroundColorAttributeName value:[WPStyleGuide readGrey] range:barRange];
        _detailLabel.attributedText = detailText;
    }
    
    if ([contentProvider respondsToSelector:@selector(unreadStatusForDisplay)]) {
        _unreadView.hidden = ![contentProvider unreadStatusForDisplay];
    } else {
        _unreadView.hidden = YES;
    }
}

- (void)setGravatarImageForContentProvider:(id<WPContentViewProvider>)contentProvider {
    
    if (![[self class] showGravatarImage]) {
        return;
    }
    
    if ([contentProvider gravatarEmailForDisplay]) {
        [_gravatarImageView setImageWithGravatarEmail:[contentProvider gravatarEmailForDisplay] fallbackImage:[UIImage imageNamed:@"comment-default-gravatar-image"]];
    } else {
        
        NSString *url = [NSString stringWithFormat:@"%@", [contentProvider blavatarURLForDisplay]];
        if (url) {
            url = [url stringByReplacingOccurrencesOfString:@"s=256" withString:[NSString stringWithFormat:@"s=%.0f", WPContentCellImageWidth * [[UIScreen mainScreen] scale]]];
            [_gravatarImageView setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"gravatar.jpg"]];
        } else {
            [_gravatarImageView setImage:[UIImage imageNamed:@"gravatar.jpg"]];
        }
    }
}

+ (BOOL)shortDateString {
    return YES;
}

+ (BOOL)showGravatarImage {
    return NO;
}

+ (BOOL)supportsUnreadStatus {
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
    return [UIFont fontWithName:@"OpenSans" size:15.0];
}

+ (UIFont *)titleFontBold
{
    return [UIFont fontWithName:@"OpenSans-Bold" size:15.0];
}

+ (NSDictionary *)titleAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 19;
    paragraphStyle.maximumLineHeight = 19;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self titleFont]};}

+ (NSDictionary *)titleAttributesBold
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 19;
    paragraphStyle.maximumLineHeight = 19;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self titleFontBold]};
}

+ (NSAttributedString *)titleAttributedTextForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    return [[NSAttributedString alloc] initWithString:[contentProvider titleForDisplay] attributes:[self titleAttributes]];
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
    
    NSDate *date = [contentProvider dateForDisplay];

    if ([[self class] shortDateString]) {
        return [date shortString];
    } else {
        static NSDateFormatter *dateFormatter = nil;
        
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd '|' HH:mm a"];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}


#pragma mark - Private Methods

+ (CGFloat)textWidth:(CGFloat)maxWidth {
    CGFloat padding = 0.0;
    padding += [[self class] textXOrigin];  // left padding
    padding += [[self class] standardOffset] + WPContentCellAccessoryViewOffset; // right padding
    return maxWidth - padding;
}

+ (CGFloat)textXOrigin {
    CGFloat x = [[self class] standardOffset];
    x += [[self class] showGravatarImage] ? [[self class] gravatarXOrigin] + WPContentCellImageWidth : 0.0;
    x += IS_RETINA ? -0.5 : 0.0;
    x += ([[self class] supportsUnreadStatus] && ![[self class] showGravatarImage] ? WPContentCellUnreadViewSide + [[self class] standardOffset] : 0.0);
    return x;
}

+ (CGFloat)gravatarXOrigin {
    CGFloat x = [[self class] standardOffset];
    x += ([[self class] supportsUnreadStatus] ? WPContentCellUnreadViewSide + [[self class] standardOffset] : 0.0);
    return x;
}

+ (CGFloat)standardOffset {
    return IS_IPAD ? WPContentCellStandardiPadOffset : WPContentCellStandardOffset;
}

+ (CGRect)gravatarImageViewFrame {
    return [[self class] showGravatarImage] ? CGRectMake([[self class] gravatarXOrigin], [[self class] standardOffset], WPContentCellImageWidth, WPContentCellImageWidth) : CGRectZero;
}

+ (CGRect)statusLabelFrameForContentProvider:(id<WPContentViewProvider>)contentProvider maxWidth:(CGFloat)maxWidth
{
    NSString *statusText = [self statusTextForContentProvider:contentProvider];
    if ([statusText length] != 0) {
        CGSize size;
        size = [statusText boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] statusAttributes] context:nil].size;
            return CGRectMake([[self class] textXOrigin], [[self class] standardOffset], size.width, size.height);
    } else {
        return CGRectMake(0, [[self class] standardOffset], 0, 0);
    }
}

+ (CGRect)titleLabelFrameForContentProvider:(id<WPContentViewProvider>)contentProvider previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
    BOOL hasStatus = [[self class] statusTextForContentProvider:contentProvider].length > 0;
    
    CGSize size;
    NSAttributedString *attributedTitle = [[self class] titleAttributedTextForContentProvider:contentProvider];
    CGFloat lineHeight = attributedTitle.size.height;
    size = [attributedTitle.string boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] titleAttributes] context:nil].size;
    size.height = ceilf(MIN(size.height, lineHeight * (WPContentCellTitleNumberOfLines - (hasStatus ? 1 : 0))));
    
    CGFloat offset = 0.0;
    if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
        offset = WPContentCellTitleAndDetailVerticalOffset;
    }
    
    return CGRectIntegral(CGRectMake([[self class] textXOrigin], CGRectGetMaxY(previousFrame) + offset, size.width, size.height));
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

+ (CGRect)unreadFrameForHeight:(CGFloat)height {
    CGFloat side = WPContentCellUnreadViewSide;
    return CGRectMake([[self class] standardOffset], (height - side) / 2.0 , side, side);
}

@end
