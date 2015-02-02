#import <UIKit/UIKit.h>

extern const CGFloat ReaderHeaderViewAvatarSize;
extern const CGFloat ReaderHeaderViewLabelHeight;

@class CircularImageView;

@interface ReaderHeaderView : UIView

/**
 A UIImage instance to be displayed as the User's avatar.
 */
@property (nonatomic, strong) UIImage *avatarImage;

/**
 A NSString representing the header's title.
 */
@property (nonatomic, strong) NSString *title;

/**
 A NSString representing the header's subtitle.
 */
@property (nonatomic, strong) NSString *subtitle;


#pragma mark - Private Subclass Methods

@property (nonatomic, strong) CircularImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

- (void)buildSubviews;
- (UILabel *)newLabelForTitle;
- (UILabel *)newLabelForSubtitle;

@end
