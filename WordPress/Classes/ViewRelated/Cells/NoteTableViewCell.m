#import "NoteTableViewCell.h"
#import "Notification.h"

#import "NSDate+StringFormatting.h"
#import "NSURL+Util.h"
#import "WPStyleGuide+Notifications.h"

#import <AFNetworking/UIKit+AFNetworking.h>




#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSInteger const NoteCellNumberOfLines            = 0;
static CGFloat const NoteCellNoticonRadius              = 10.0f;
static NSString * const NoteCellPlaceholderImageName    = @"gravatar";


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface NoteTableViewCell ()
@property (nonatomic, weak, readwrite) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak, readwrite) IBOutlet UILabel     *noticonLabel;
@property (nonatomic, weak, readwrite) IBOutlet UIView      *noticonView;
@property (nonatomic, weak, readwrite) IBOutlet UILabel     *subjectLabel;
@property (nonatomic, weak, readwrite) IBOutlet UILabel     *timestampLabel;
@end


#pragma mark ====================================================================================
#pragma mark NoteTableViewCell
#pragma mark ====================================================================================

@implementation NoteTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSAssert(self.noticonView, nil);
    NSAssert(self.noticonLabel, nil);
    NSAssert(self.subjectLabel, nil);
    NSAssert(self.timestampLabel, nil);
    
    self.noticonView.layer.cornerRadius     = NoteCellNoticonRadius;
    self.noticonView.backgroundColor        = [WPStyleGuide notificationIconColor];
    self.noticonLabel.font                  = [WPStyleGuide notificationIconFont];
    self.noticonLabel.textColor             = [UIColor whiteColor];
    
    self.subjectLabel.numberOfLines         = NoteCellNumberOfLines;
    self.subjectLabel.backgroundColor       = [UIColor clearColor];
    self.subjectLabel.textAlignment         = NSTextAlignmentLeft;
    self.subjectLabel.lineBreakMode         = NSLineBreakByWordWrapping;
    self.subjectLabel.shadowOffset          = CGSizeZero;
    self.subjectLabel.font                  = [WPStyleGuide notificationSubjectFont];
    self.subjectLabel.textColor             = [WPStyleGuide littleEddieGrey];
    
    self.timestampLabel.textAlignment       = NSTextAlignmentRight;
    self.timestampLabel.font                = [WPStyleGuide notificationSubjectFont];
    self.timestampLabel.textColor           = [WPStyleGuide notificationTimestampTextColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.contentView layoutIfNeeded];
    [self refreshLabelPreferredMaxLayoutWidth];
}

- (void)refreshLabelPreferredMaxLayoutWidth
{
    CGFloat width = CGRectGetMinX(self.timestampLabel.frame) - 2 - CGRectGetMinX(self.subjectLabel.frame);
    self.subjectLabel.preferredMaxLayoutWidth = width;
}


#pragma mark - Properties

- (NSAttributedString *)attributedSubject
{
    return self.subjectLabel.attributedText;
}

- (void)setAttributedSubject:(NSAttributedString *)subject
{
    self.subjectLabel.attributedText = subject;
    [self setNeedsLayout];
}

- (void)setRead:(BOOL)read
{
    _read = read;
    [self refreshBackgrounds];
}

- (void)setNoticon:(NSString *)noticon
{
    _noticon = noticon;
    self.noticonLabel.text = noticon;
}

- (void)setIconURL:(NSURL *)iconURL
{
    if ([iconURL isEqual:_iconURL]) {
        return;
    }
    
    _iconURL = iconURL;
    
    // Download the image, only if needed
    if (!iconURL) {
        return;
    }
    
    // If needed, patch gravatar URL's with the required size. This will help us minimize bandwith usage
    CGFloat size            = CGRectGetWidth(self.iconImageView.frame) * [[UIScreen mainScreen] scale];
    NSURL *scaledURL        = [iconURL patchGravatarUrlWithSize:size];
    UIImage *placeholder    = [UIImage imageNamed:NoteCellPlaceholderImageName];
    [_iconImageView setImageWithURL:scaledURL placeholderImage:placeholder];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    [self refreshBackgrounds];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animate
{
    [super setSelected:selected animated:animate];
    [self refreshBackgrounds];
}

- (void)setTimestamp:(NSDate *)timestamp
{
    self.timestampLabel.text = [timestamp shortString];
    _timestamp = timestamp;
}


#pragma mark - Public Helpers

- (CGFloat)heightForWidth:(CGFloat)width
{
    // Setup the cell with the given width
    self.bounds = CGRectMake(0.0f, 0.0f, width, CGRectGetHeight(self.bounds));
    
    // Force layout
    [self layoutIfNeeded];
    
    // Calculate the height: There is an ugly bug where the calculated height might be off by 1px, thus, clipping the text
    CGFloat const NoteCellHeightPadding = 1;
    
    // iPad: Limit the width
    CGFloat cappedWidth = IS_IPAD ? WPTableViewFixedWidth : width;
    CGSize size = [self.contentView systemLayoutSizeFittingSize:CGSizeMake(cappedWidth, 0.0f)];
    
    return ceil(size.height) + NoteCellHeightPadding;
}


#pragma mark - Private Helpers

- (void)refreshBackgrounds
{
    if (_read) {
        self.noticonView.backgroundColor    = [WPStyleGuide notificationIconReadColor];
        self.backgroundColor                = [WPStyleGuide notificationBackgroundReadColor];
    } else {
        self.noticonView.backgroundColor    = [WPStyleGuide notificationIconUnreadColor];
        self.backgroundColor                = [WPStyleGuide notificationBackgroundUnreadColor];
    }
}


#pragma mark - Static Helpers

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

+ (NSString *)layoutIdentifier
{
    return [NSString stringWithFormat:@"%@-layout", NSStringFromClass([self class])];
}

@end
