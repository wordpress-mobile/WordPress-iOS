#import "PostFeaturedImageCell.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "WordPress-Swift.h"

CGFloat const PostFeaturedImageCellMargin = 15.0f;

@interface PostFeaturedImageCell ()

@property (nonatomic, strong) CachedAnimatedImageView *featuredImageView;
@property (nonatomic, strong) ImageLoader *imageLoader;

@end

@implementation PostFeaturedImageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    [self layoutImageView];
    _imageLoader = [[ImageLoader alloc] initWithImageView:self.featuredImageView gifStrategy:GIFStrategyLargeGIFs];
}

- (void)setImageWithURL:(NSURL *)url inPost:(id<ImageSourceInformation>)postInformation withSize:(CGSize)size
{
    __weak PostFeaturedImageCell *weakSelf = self;
    [self.imageLoader loadImageWithURL:url fromPost:postInformation preferedSize:size placeholder:nil success:^{
        if (weakSelf && weakSelf.delegate) {
            [weakSelf.delegate postFeatureImageCellDidFinishLoadingImage:weakSelf];
        }
    } error:^(NSError * _Nullable error) {
        if (weakSelf && weakSelf.delegate) {
            [weakSelf.delegate postFeatureImageCell:weakSelf didFinishLoadingImageWithError:error];
        }
    }];
}

- (UIImage *)image
{
    return self.featuredImageView.image;
}

#pragma mark - Helpers

- (CachedAnimatedImageView *)featuredImageView
{
    if (!_featuredImageView) {
        _featuredImageView = [[CachedAnimatedImageView alloc] init];
        _featuredImageView.contentMode = UIViewContentModeScaleAspectFill;
        _featuredImageView.clipsToBounds = YES;
        _featuredImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }

    return _featuredImageView;
}

- (void)layoutImageView
{
    UIView *imageView = self.featuredImageView;

    [self.contentView addSubview:imageView];
    UILayoutGuide *readableGuide = self.contentView.readableContentGuide;
    [NSLayoutConstraint activateConstraints:@[
                                              [imageView.leadingAnchor constraintEqualToAnchor:readableGuide.leadingAnchor],
                                              [imageView.trailingAnchor constraintEqualToAnchor:readableGuide.trailingAnchor],
                                              [imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:PostFeaturedImageCellMargin],
                                              [imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-PostFeaturedImageCellMargin]
                                              ]];
}

@end
