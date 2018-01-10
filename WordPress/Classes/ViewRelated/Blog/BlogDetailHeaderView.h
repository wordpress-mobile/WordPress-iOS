#import <UIKit/UIKit.h>

extern const CGFloat BlogDetailHeaderViewBlavatarSize;

@protocol BlogDetailHeaderViewDelegate

- (void)siteIconTapped;
- (void)siteIconReceivedDroppedImage:(UIImage *)image;
- (BOOL)siteIconShouldAllowDroppedImages;

@end

@class Blog;

@interface BlogDetailHeaderView : UIView

@property (nonatomic, strong) UIImageView *blavatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, weak) id<BlogDetailHeaderViewDelegate> delegate;
@property (nonatomic) BOOL updatingIcon;

- (void)refreshIconImage;
- (void)setTitleText:(NSString *)title;
- (void)setSubtitleText:(NSString *)subtitle;
- (void)loadImageAtPath:(NSString *)imagePath;

@end
