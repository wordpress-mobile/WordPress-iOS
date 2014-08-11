#import "NoteTableViewCell.h"
#import "Notification.h"

#import "NSDate+StringFormatting.h"
#import "NSURL+Util.h"
#import "WPStyleGuide+Notifications.h"

#import <AFNetworking/UIKit+AFNetworking.h>




#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSInteger const NoteCellNumberOfLines            = 5;
static CGFloat const NoteCellUnreadRadius               = 4.0f;
static CGFloat const NoteCellNoticonRadius              = 10.0f;
static NSString * const NoteCellPlaceholderImageName    = @"gravatar";


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface NoteTableViewCell ()
@property (nonatomic, weak, readwrite) IBOutlet UIView      *unreadView;
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

    NSAssert(self.unreadView, nil);
    NSAssert(self.subjectLabel, nil);
    
    self.unreadView.backgroundColor         = [WPStyleGuide newKidOnTheBlockBlue];
    self.unreadView.layer.cornerRadius      = NoteCellUnreadRadius;

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
    self.unreadView.backgroundColor = [WPStyleGuide newKidOnTheBlockBlue];
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

- (BOOL)read
{
    return self.unreadView.hidden;
}

- (void)setRead:(BOOL)read
{
    self.unreadView.hidden = read;
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
    self.noticonView.backgroundColor = [WPStyleGuide notificationIconColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animate
{
    [super setSelected:selected animated:animate];
    self.noticonView.backgroundColor = [WPStyleGuide notificationIconColor];
}

- (void)setTimestamp:(NSDate *)timestamp
{
    self.timestampLabel.text = [timestamp shortString];
    _timestamp = timestamp;
}

#pragma mark - Static Helpers

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

+ (NSString *)layoutIdentifier
{
    return @"layoutIdentifier";
}

@end
