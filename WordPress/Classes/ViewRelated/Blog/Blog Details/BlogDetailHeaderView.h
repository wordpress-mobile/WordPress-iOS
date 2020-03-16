#import <UIKit/UIKit.h>

extern const CGFloat BlogDetailHeaderViewBlavatarSize;

@protocol BlogDetailHeaderViewDelegate

- (void)siteIconTapped;
- (void)siteIconReceivedDroppedImage:(UIImage * _Nullable)image;
- (BOOL)siteIconShouldAllowDroppedImages;

@end

@class Blog;

@interface BlogDetailHeaderView : UIView

@property (nonatomic, strong, nonnull) UIImageView *blavatarImageView;
@property (nonatomic, strong, nonnull) UILabel *titleLabel;
@property (nonatomic, strong, nonnull) UILabel *subtitleLabel;
@property (nonatomic, strong, nullable) Blog *blog;
@property (nonatomic, weak, nullable) id<BlogDetailHeaderViewDelegate> delegate;
@property (nonatomic) BOOL updatingIcon;

- (void)refreshIconImage;
- (void)setTitleText:(NSString * _Nullable)title;
- (void)setSubtitleText:(NSString * _Nullable)subtitle;
- (void)loadImageAtPath:(NSString * _Nonnull)imagePath;

@end
