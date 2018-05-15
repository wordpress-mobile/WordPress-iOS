#import <WordPressShared/WPTableViewCell.h>

@protocol PostInformation;
@class PostFeaturedImageCell;

@protocol PostFeaturedImageCellDelegate <NSObject>
- (void)postFeatureImageCellDidFinishLoadingImage:(PostFeaturedImageCell *)cell;
- (void)postFeatureImageCell:(PostFeaturedImageCell *)cell didFinishLoadingAnimatedImageWithData:(NSData *)animationData;
- (void)postFeatureImageCell:(PostFeaturedImageCell *)cell didFinishLoadingImageWithError:(NSError *)error;
@end

@interface PostFeaturedImageCell : WPTableViewCell

extern CGFloat const PostFeaturedImageCellMargin;

@property (weak, nonatomic) id<PostFeaturedImageCellDelegate> delegate;
@property (strong, nonatomic, readonly) UIImage *image;

- (void)setImageWithURL:(NSURL *)url inPost:(id<PostInformation>)postInformation withSize:(CGSize)size;

@end
