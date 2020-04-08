#import <WordPressShared/WPTableViewCell.h>

@class AbstractPost;
@class PostFeaturedImageCell;

@protocol PostFeaturedImageCellDelegate <NSObject>
- (void)postFeatureImageCellDidFinishLoadingImage:(nonnull PostFeaturedImageCell *)cell;
- (void)postFeatureImageCell:(nonnull PostFeaturedImageCell *)cell didFinishLoadingAnimatedImageWithData:(nullable NSData *)animationData;
- (void)postFeatureImageCell:(nonnull PostFeaturedImageCell *)cell didFinishLoadingImageWithError:(nullable NSError *)error;
@end

@interface PostFeaturedImageCell : WPTableViewCell

extern CGFloat const PostFeaturedImageCellMargin;

@property (weak, nonatomic, nullable) id<PostFeaturedImageCellDelegate> delegate;
@property (strong, nonatomic, readonly, nullable) UIImage *image;

- (void)setImageWithURL:(nonnull NSURL *)url inPost:(nonnull AbstractPost *)post withSize:(CGSize)size;

@end
