#import "WPTableViewCell.h"

@interface PostFeaturedImageCell : WPTableViewCell

extern CGFloat const PostFeaturedImageCellMargin;

- (void)setImage:(UIImage *)image;
- (void)showLoadingSpinner:(BOOL)showSpinner;

@end
