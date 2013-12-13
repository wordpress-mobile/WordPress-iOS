//
//  WPContentCell.m
//  
//
//  Created by Tom Witkin on 12/12/13.
//
//

#import "WPContentCell.h"
#import "Post.h"
#import "NSString+XMLExtensions.h"
#import "WPComLanguages.h"

@interface WPContentCell() {
    AbstractPost __weak *_post;
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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
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
    
    _statusLabel.frame = [[self class] statusLabelFrameForPost:self.post maxWidth:maxWidth];
    _titleLabel.frame = [[self class] titleLabelFrameForPost:self.post previousFrame:_statusLabel.frame maxWidth:maxWidth];
    _detailLabel.frame = [[self class] detailLabelFrameForPost:self.post previousFrame:_titleLabel.frame maxWidth:maxWidth];
}

+ (CGFloat)rowHeightForPost:(AbstractPost *)post andWidth:(CGFloat)width;
{
    CGRect statusFrame = [[self class] statusLabelFrameForPost:post maxWidth:width];
    CGRect titleFrame = [[self class] titleLabelFrameForPost:post previousFrame:statusFrame maxWidth:width];
    CGRect detailFrame = [[self class] detailLabelFrameForPost:post previousFrame:titleFrame maxWidth:width];
    
    return CGRectGetMaxY(detailFrame) + WPContentCellStandardOffset;
}

- (AbstractPost *)post
{
    return _post;
}

- (void)setPost:(AbstractPost *)post
{
    _post = post;
    
    _titleLabel.text = [[self class] titleText:post];
    _statusLabel.text = [[self class] statusTextForPost:post];
    _statusLabel.textColor = [[self class] statusColorForPost:post];
    _detailLabel.text = [[self class] detailText:post];
    
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

+ (UIFont *)statusFont
{
    return [WPStyleGuide labelFont];
}

+ (NSDictionary *)statusAttributes
{
    return [WPStyleGuide labelAttributes];
}

+ (NSString *)statusTextForPost:(AbstractPost *)post
{
    if (post.remoteStatus == AbstractPostRemoteStatusSync) {
        if ([post.status isEqualToString:@"pending"]) {
            return [NSLocalizedString(@"Pending", @"") uppercaseString];
        } else if ([post.status isEqualToString:@"draft"]) {
            return [post.statusTitle uppercaseString];
        } else {
            return @"";
        }
    } else {
        NSString *statusText = [self addEllipsesIfAppropriate:[AbstractPost titleForRemoteStatus:@((int)post.remoteStatus)]];
        return [statusText uppercaseString];
    }
}

+ (NSString *)addEllipsesIfAppropriate:(NSString *)statusText
{
    if ([statusText isEqualToString:NSLocalizedString(@"Uploading", nil)]) {
        if ([WPComLanguages isRightToLeft]) {
            return [NSString stringWithFormat:@"…%@", statusText];
        } else {
            return [NSString stringWithFormat:@"%@…", statusText];
        }
    }
    return statusText;
}

+ (UIColor *)statusColorForPost:(AbstractPost *)post
{
    if (post.remoteStatus == AbstractPostRemoteStatusSync) {
        if ([post.status isEqualToString:@"pending"]) {
            return [UIColor lightGrayColor];
        } else if ([post.status isEqualToString:@"draft"]) {
            return [WPStyleGuide jazzyOrange];
        } else {
            return [UIColor blackColor];
        }
    } else {
        if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
            return [WPStyleGuide newKidOnTheBlockBlue];
        } else if (post.remoteStatus == AbstractPostRemoteStatusFailed) {
            return [WPStyleGuide fireOrange];
        } else {
            return [WPStyleGuide jazzyOrange];
        }
    }
}

+ (UIFont *)titleFont
{
    return [UIFont fontWithName:@"OpenSans" size:18.0];
}

+ (NSDictionary *)titleAttributes
{
    return [WPStyleGuide postTitleAttributes];
}

+ (NSString *)titleText:(AbstractPost *)post
{
    NSString *title = [[post valueForKey:@"postTitle"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (title == nil || ([title length] == 0)) {
        title = NSLocalizedString(@"(no title)", @"");
    }
    return [title stringByDecodingXMLCharacters];
}

+ (UIFont *)detailFont
{
    return [WPStyleGuide subtitleFont];
}

+ (NSDictionary *)detailAttributes
{
    return [WPStyleGuide subtitleAttributes];
}

+ (NSString *)detailText:(AbstractPost *)post
{
    static NSDateFormatter *dateFormatter = nil;
    
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd '|' HH:mm a"];
    }
    
    NSDate *date = [post valueForKey:@"dateCreated"];
    return [dateFormatter stringFromDate:date];
}


#pragma mark - Private Methods

+ (CGFloat)textWidth:(CGFloat)maxWidth
{
    return maxWidth - WPContentCellStandardOffset - WPContentCellAccessoryViewOffset;
}

+ (CGRect)statusLabelFrameForPost:(AbstractPost *)post maxWidth:(CGFloat)maxWidth
{
    NSString *statusText = [self statusTextForPost:post];
    if ([statusText length] != 0) {
        CGSize size;
        size = [statusText boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] statusAttributes] context:nil].size;
        if (IS_RETINA) {
            return CGRectMake(WPContentCellStandardOffset + WPContentCellLabelAndTitleHorizontalOffset, WPContentCellStandardOffset, size.width, size.height);
        } else {
            return CGRectMake(WPContentCellStandardOffset, WPContentCellStandardOffset, size.width, size.height);
        }
    } else {
        return CGRectMake(0, WPContentCellStandardOffset, 0, 0);
    }
}

+ (CGRect)titleLabelFrameForPost:(AbstractPost *)post previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
    CGSize size;
    size = [[[self class] titleText:post] boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] titleAttributes] context:nil].size;
    
    CGFloat offset = 0.0;
    if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
        offset = WPContentCellTitleAndDetailVerticalOffset;
    }
    
    if (IS_RETINA) {
        return CGRectMake(WPContentCellStandardOffset + WPContentCellLabelAndTitleHorizontalOffset, CGRectGetMaxY(previousFrame) + offset, size.width, size.height);
    } else {
        return CGRectIntegral(CGRectMake(WPContentCellStandardOffset, CGRectGetMaxY(previousFrame) + offset, size.width, size.height));
    }
}

+ (CGRect)detailLabelFrameForPost:(AbstractPost *)post previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
    CGSize size;
    size = [[[self class] detailText:post] boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] detailAttributes] context:nil].size;
    
    CGFloat offset = 0.0;
    if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
        offset = WPContentCellTitleAndDetailVerticalOffset;
    }
    
    return CGRectIntegral(CGRectMake(WPContentCellStandardOffset, CGRectGetMaxY(previousFrame) + offset, size.width, size.height));
}

@end
