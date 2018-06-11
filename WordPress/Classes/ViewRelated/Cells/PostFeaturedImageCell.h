#import <WordPressShared/WPTableViewCell.h>

@protocol ImageSourceInformation;
@class PostFeaturedImageCell;

@protocol PostFeaturedImageCellDelegate <NSObject>
- (void)postFeatureImageCellDidFinishLoadingImage:(PostFeaturedImageCell *)cell;
- (void)postFeatureImageCell:(PostFeaturedImageCell *)cell didFinishLoadingAnimatedImageWithData:(NSData *)animationData;
- (void)postFeatureImageCell:(PostFeaturedImageCell *)cell didFinishLoadingImageWithError:(NSError *)error;
@end

@interface PostFeaturedImageCell : WPTableViewCell

extern CGFloat const PostFeaturedImageCellMargin;

@property (weak, nonatomic, nullable) id<PostFeaturedImageCellDelegate> delegate;
@property (strong, nonatomic, readonly, nullable) UIImage *image;

- (void)setImageWithURL:(nonnull NSURL *)url inPost:(nonnull id<ImageSourceInformation>)postInformation withSize:(CGSize)size;

@end
