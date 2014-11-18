#import "WordPress-Swift.h"
#import "WPContentCell.h"

#import <AFNetworking/UIKit+AFNetworking.h>
#import "UIImageView+AFNetworkingExtra.h"
#import "WPComLanguages.h"
#import "UIImageView+Gravatar.h"
#import "NSDate+StringFormatting.h"
#import "NSString+Util.h"
#import <WordPress-iOS-Shared/WPFontManager.h>

@interface WPContentCell() {
    CircularImageView *_gravatarImageView;
    UILabel *_statusLabel;
    UILabel *_titleLabel;
    UILabel *_dateLabel;
    UIImageView *_dateImageView;
    UIImageView *_unreadView;
}
@end

@implementation WPContentCell

CGFloat const WPContentCellStandardOffset                   = 10.0;
CGFloat const WPContentCellVerticalPadding                  = 10.0;
CGFloat const WPContentCellTitleAndDateVerticalOffset       = 3.0;
CGFloat const WPContentCellLabelAndTitleHorizontalOffset    = -0.5;
CGFloat const WPContentCellAccessoryViewOffset              = 25.0;
CGFloat const WPContentCellImageWidth                       = 70.0;
CGFloat const WPContentCellTitleNumberOfLines               = 3;
CGFloat const WPContentCellUnreadViewSide                   = 10.0;
CGFloat const WPContentCellUnreadDotSize                    = 8.0;
CGFloat const WPContentCellDateImageSide                    = 16.0;
CGFloat const WPContentCellDefaultOrigin                    = 15.0f;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

        _gravatarImageView = [[CircularImageView alloc] init];
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

        _dateLabel = [[UILabel alloc] init];
        _dateLabel.backgroundColor = [UIColor clearColor];
        _dateLabel.textAlignment = NSTextAlignmentLeft;
        _dateLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _dateLabel.font = [[self class] dateFont];
        _dateLabel.shadowOffset = CGSizeMake(0.0, 0.0);
        _dateLabel.textColor = [WPStyleGuide allTAllShadeGrey];
        [self.contentView addSubview:_dateLabel];

        _dateImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reader-postaction-time"]];
        [_dateImageView sizeToFit];
        [self.contentView addSubview:_dateImageView];

        if ([[self class] supportsUnreadStatus]) {
            _unreadView = [[UIImageView alloc] init];

            // create circular image
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(WPContentCellUnreadViewSide, WPContentCellUnreadViewSide), NO, 0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0, WPContentCellUnreadDotSize, WPContentCellUnreadDotSize) cornerRadius:3.0].CGPath);

            CGContextSetFillColorWithColor(context, [WPStyleGuide newKidOnTheBlockBlue].CGColor);
            CGContextFillPath(context);
            _unreadView.image = UIGraphicsGetImageFromCurrentImageContext();

            [self.contentView addSubview:_unreadView];
        }
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    _gravatarImageView.image = nil;
    _unreadView.hidden = YES;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat maxWidth = CGRectGetWidth(self.bounds);

    _gravatarImageView.frame = [[self class] gravatarImageViewFrame];

    CGRect statusFrame = [[self class] statusLabelFrameForContentProvider:self.contentProvider maxWidth:maxWidth];
    CGRect titleFrame = [[self class] titleLabelFrameForContentProvider:self.contentProvider previousFrame:statusFrame maxWidth:maxWidth];
    CGRect dateFrame = [[self class] dateLabelFrameForContentProvider:self.contentProvider previousFrame:titleFrame maxWidth:maxWidth];

    // Center title and date frame if Gravatar is shown
    if ([[self class] showGravatarImage] && CGRectGetMaxY(dateFrame) < CGRectGetMaxY(_gravatarImageView.frame)) {
        CGFloat heightOfControls = CGRectGetMaxY(dateFrame) - CGRectGetMinY(statusFrame);
        CGFloat startingYForCenteredControls = floorf((CGRectGetHeight(_gravatarImageView.frame) - heightOfControls)/2.0) + CGRectGetMinY(_gravatarImageView.frame);
        CGFloat offsetToCenter = MIN(CGRectGetMinY(statusFrame) - startingYForCenteredControls, 0);

        statusFrame.origin.y -= offsetToCenter;
        titleFrame.origin.y -= offsetToCenter;
        dateFrame.origin.y -= offsetToCenter;
    }

    _statusLabel.frame = statusFrame;
    _titleLabel.frame = titleFrame;
    _dateLabel.frame = dateFrame;
    _unreadView.frame = [[self class] unreadFrameForHeight:CGRectGetHeight(self.bounds)];

    // layout date image
    _dateImageView.hidden = !(_dateLabel.text.length > 0);
    if (!_dateImageView.hidden) {
        _dateImageView.frame = CGRectMake(CGRectGetMinX(dateFrame) - WPContentCellDateImageSide - 2, CGRectGetMidY(dateFrame) - WPContentCellDateImageSide / 2.0, WPContentCellDateImageSide, WPContentCellDateImageSide);
    }
}

+ (CGFloat)rowHeightForContentProvider:(id<WPContentViewProvider>)contentProvider andWidth:(CGFloat)width;
{
    CGRect gravatarFrame = [[self class] gravatarImageViewFrame];
    CGRect statusFrame = [[self class] statusLabelFrameForContentProvider:contentProvider maxWidth:width];
    CGRect titleFrame = [[self class] titleLabelFrameForContentProvider:contentProvider previousFrame:statusFrame maxWidth:width];
    CGRect dateFrame = [[self class] dateLabelFrameForContentProvider:contentProvider previousFrame:titleFrame maxWidth:width];

    return MAX(CGRectGetMaxY(gravatarFrame), CGRectGetMaxY(dateFrame)) + WPContentCellVerticalPadding;
}

- (void)setContentProvider:(id<WPContentViewProvider>)contentProvider
{
    _contentProvider = contentProvider;

    [self setGravatarImageForContentProvider:contentProvider];

    _titleLabel.attributedText = [[self class] titleAttributedTextForContentProvider:contentProvider];
    _statusLabel.text = [[self class] statusTextForContentProvider:contentProvider];
    _statusLabel.textColor = [[self class] statusColorForContentProvider:contentProvider];
    _dateLabel.text = [[self class] dateTextForContentProvider:contentProvider];

    if (_statusLabel.text != nil) {
        _statusLabel.attributedText = [[NSAttributedString alloc] initWithString:_statusLabel.text attributes:[[self class] statusAttributes]];
        _titleLabel.numberOfLines = WPContentCellTitleNumberOfLines - 1;
    }

    if (_dateLabel.text != nil) {
        NSRange barRange = [_dateLabel.text rangeOfString:@"|"];
        NSMutableAttributedString *dateText = [[NSMutableAttributedString alloc] initWithString:_dateLabel.text attributes:[[self class] dateAttributes]];
        [dateText addAttribute:NSForegroundColorAttributeName value:[WPStyleGuide readGrey] range:barRange];
        _dateLabel.attributedText = dateText;
    }

    if ([contentProvider respondsToSelector:@selector(unreadStatusForDisplay)]) {
        _unreadView.hidden = ![contentProvider unreadStatusForDisplay];
    } else {
        _unreadView.hidden = YES;
    }
}

- (void)setGravatarImageForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    if (![[self class] showGravatarImage]) {
        return;
    }

    if ([contentProvider gravatarEmailForDisplay]) {
        [_gravatarImageView setImageWithGravatarEmail:[contentProvider gravatarEmailForDisplay] fallbackImage:[UIImage imageNamed:@"gravatar"]];
    } else {

        NSString *url = [NSString stringWithFormat:@"%@", [contentProvider avatarURLForDisplay]];
        if (url) {
            url = [url stringByReplacingOccurrencesOfString:@"s=256" withString:[NSString stringWithFormat:@"s=%.0f", WPContentCellImageWidth * [[UIScreen mainScreen] scale]]];
            [_gravatarImageView setImageWithURL:[NSURL URLWithString:url] emptyCachePlaceholderImage:[UIImage imageNamed:@"gravatar"] ];
        } else {
            [_gravatarImageView setImage:[UIImage imageNamed:@"gravatar"]];
        }
    }
}

+ (BOOL)shortDateString
{
    return YES;
}

+ (BOOL)showGravatarImage
{
    return NO;
}

+ (BOOL)supportsUnreadStatus
{
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
    return [[contentProvider statusForDisplay] uppercaseStringWithLocale:[NSLocale currentLocale]];
}

+ (UIColor *)statusColorForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    return [WPStyleGuide jazzyOrange];
}

+ (UIFont *)titleFont
{
    return [WPFontManager openSansRegularFontOfSize:14.0];
}

+ (UIFont *)titleFontBold
{
    return [WPFontManager openSansBoldFontOfSize:14.0];
}

+ (NSDictionary *)titleAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 18;
    paragraphStyle.maximumLineHeight = 18;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self titleFont]};}

+ (NSDictionary *)titleAttributesBold
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = 18;
    paragraphStyle.maximumLineHeight = 18;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self titleFontBold]};
}

+ (NSAttributedString *)titleAttributedTextForContentProvider:(id<WPContentViewProvider>)contentProvider
{
    // remove new lines from title
    NSString *titleText = [contentProvider titleForDisplay];
    return [[NSAttributedString alloc] initWithString:titleText attributes:[self titleAttributes]];
}

+ (UIFont *)dateFont
{
    return [WPStyleGuide subtitleFont];
}

+ (NSDictionary *)dateAttributes
{
    return [WPStyleGuide subtitleAttributes];
}

+ (NSString *)dateTextForContentProvider:(id<WPContentViewProvider>)contentProvider
{

    NSDate *date = [contentProvider dateForDisplay];

    if ([[self class] shortDateString]) {
        return [date shortString];
    }

    static NSDateFormatter *dateFormatter = nil;

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    }

    return [dateFormatter stringFromDate:date];
}

#pragma mark - Private Methods

+ (CGFloat)textWidth:(CGFloat)maxWidth
{
    CGFloat padding = 0.0;
    padding += [[self class] textXOrigin];  // left padding
    padding += WPContentCellStandardOffset + WPContentCellAccessoryViewOffset; // right padding
    return maxWidth - padding;
}

+ (CGFloat)contentXOrigin
{
    CGFloat x = 15.0;
    x += ([[self class] supportsUnreadStatus] ? 10.0 : 0.0);
    x += IS_RETINA ? -0.5 : 0.0;
    return x;
}

+ (CGFloat)textXOrigin
{
    if ([[self class] showGravatarImage]) {
        return ([[self class] gravatarXOrigin] + WPContentCellImageWidth + WPContentCellStandardOffset);
    }

    return WPContentCellDefaultOrigin;
}

+ (CGFloat)gravatarXOrigin
{
    return [[self class] contentXOrigin];
}

+ (CGRect)gravatarImageViewFrame
{
    return [[self class] showGravatarImage] ? CGRectMake([[self class] gravatarXOrigin], WPContentCellStandardOffset, WPContentCellImageWidth, WPContentCellImageWidth) : CGRectZero;
}

+ (CGRect)statusLabelFrameForContentProvider:(id<WPContentViewProvider>)contentProvider maxWidth:(CGFloat)maxWidth
{
    NSString *statusText = [self statusTextForContentProvider:contentProvider];
    if ([statusText length] != 0) {
        CGSize size;
        size = [statusText boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] statusAttributes] context:nil].size;
            return CGRectMake([[self class] textXOrigin], WPContentCellVerticalPadding, size.width, size.height);
    }

    return CGRectMake(0, WPContentCellVerticalPadding, 0, 0);
}

+ (CGRect)titleLabelFrameForContentProvider:(id<WPContentViewProvider>)contentProvider previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
    BOOL hasStatus = [[self class] statusTextForContentProvider:contentProvider].length > 0;

    CGSize size;
    NSAttributedString *attributedTitle = [[self class] titleAttributedTextForContentProvider:contentProvider];
    CGFloat lineHeight = attributedTitle.size.height;
    size = [attributedTitle boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    size.height = ceilf(MIN(size.height, lineHeight * (WPContentCellTitleNumberOfLines - (hasStatus ? 1 : 0)))) + 1;

    CGFloat offset = -2.0; // Account for line height of title
    if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
        offset += WPContentCellTitleAndDateVerticalOffset;
    }

    return CGRectIntegral(CGRectMake([[self class] textXOrigin], CGRectGetMaxY(previousFrame) + offset, size.width, size.height));
}

+ (CGRect)dateLabelFrameForContentProvider:(id<WPContentViewProvider>)contentProvider previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
    CGSize size;
    size = [[[self class] dateTextForContentProvider:contentProvider] boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth] - WPContentCellDateImageSide, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] dateAttributes] context:nil].size;

    CGFloat offset = 0.0;
    if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
        offset = WPContentCellTitleAndDateVerticalOffset;
    }

    return CGRectIntegral(CGRectMake([[self class] textXOrigin] + WPContentCellDateImageSide, CGRectGetMaxY(previousFrame) + offset, size.width, size.height));
}

+ (CGRect)unreadFrameForHeight:(CGFloat)height
{
    CGFloat side = WPContentCellUnreadViewSide;
    return CGRectMake(([[self class] gravatarXOrigin] - side) / 2.0, (height - side) / 2.0 , side, side);
}

@end
