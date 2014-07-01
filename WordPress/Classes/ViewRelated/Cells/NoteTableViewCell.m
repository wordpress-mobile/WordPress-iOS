#import "NoteTableViewCell.h"
#import "Notification.h"

#import "NSDate+StringFormatting.h"
#import "NSURL+Util.h"
#import "WPStyleGuide+Notifications.h"

#import <AFNetworking/UIKit+AFNetworking.h>




#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static CGFloat const NoteCellHeight                     = 90.0f;
static CGFloat const NoteCellUnreadRadius               = 4.0f;
static CGFloat const NoteCellNoticonRadius              = 12.0f;
static NSInteger const NoteCellNumberOfLines            = 3;
static NSString * const NoteCellPlaceholderImageName    = @"gravatar";
static NSString * const NoteCellDateImageName           = @"reader-postaction-time";


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface NoteTableViewCell ()
@property (nonatomic, weak, readwrite) IBOutlet UIView      *unreadView;
@property (nonatomic, weak, readwrite) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak, readwrite) IBOutlet UIImageView *dateImageView;
@property (nonatomic, weak, readwrite) IBOutlet UILabel     *noticonLabel;
@property (nonatomic, weak, readwrite) IBOutlet UIView      *noticonView;
@property (nonatomic, weak, readwrite) IBOutlet UILabel     *subjectLabel;
@property (nonatomic, weak, readwrite) IBOutlet UILabel     *dateLabel;
@end


#pragma mark ====================================================================================
#pragma mark NoteTableViewCell
#pragma mark ====================================================================================

@implementation NoteTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSAssert(self.unreadView, nil);
    NSAssert(self.dateImageView, nil);
    NSAssert(self.subjectLabel, nil);
    NSAssert(self.dateLabel, nil);
    
    self.unreadView.backgroundColor         = [WPStyleGuide newKidOnTheBlockBlue];
    self.unreadView.layer.cornerRadius      = NoteCellUnreadRadius;

    self.noticonView.layer.cornerRadius     = NoteCellNoticonRadius;
    self.noticonView.backgroundColor        = [WPStyleGuide notificationIconColor];
    self.noticonLabel.font                  = [WPStyleGuide notificationIconFont];
    self.noticonLabel.textColor             = [UIColor whiteColor];
    
    self.dateImageView.image                = [UIImage imageNamed:NoteCellDateImageName];
    [self.dateImageView sizeToFit];
    
    self.subjectLabel.backgroundColor       = [UIColor clearColor];
    self.subjectLabel.textAlignment         = NSTextAlignmentLeft;
    self.subjectLabel.numberOfLines         = NoteCellNumberOfLines;
    self.subjectLabel.lineBreakMode         = NSLineBreakByWordWrapping;
    self.subjectLabel.shadowOffset          = CGSizeZero;
    self.subjectLabel.font                  = [WPStyleGuide notificationSubjectFont];
    self.subjectLabel.textColor             = [WPStyleGuide littleEddieGrey];
    
    self.dateLabel.backgroundColor          = [UIColor clearColor];
    self.dateLabel.textAlignment            = NSTextAlignmentLeft;
    self.dateLabel.lineBreakMode            = NSLineBreakByWordWrapping;
    self.dateLabel.font                     = [WPStyleGuide subtitleFont];
    self.dateLabel.shadowOffset             = CGSizeZero;
    self.dateLabel.textColor                = [WPStyleGuide allTAllShadeGrey];
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

- (void)setTimestamp:(NSDate *)timestamp
{
    if ([_timestamp isEqual:timestamp]) {
        return;
    }
    
    _timestamp = timestamp;
    self.dateLabel.text = [timestamp shortString];
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


#pragma mark - Static Helpers

+ (CGFloat)calculateHeightForNote:(Notification *)note
{
    return NoteCellHeight;
}

+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
