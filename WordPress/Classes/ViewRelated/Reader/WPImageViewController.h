#import <UIKit/UIKit.h>

@import Photos;
@import WPMediaPicker;

@class Media;

NS_ASSUME_NONNULL_BEGIN
@interface WPImageViewController : UIViewController

@property (nonatomic, readonly, nullable) id<WPMediaAsset> mediaAsset;
@property (nonatomic, assign) BOOL shouldDismissWithGestures;

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithMedia:(Media *)media;
- (instancetype)initWithAsset:(PHAsset *)asset;
- (instancetype)initWithGifData:(NSData *)data;
- (instancetype)initWithExternalMediaURL:(NSURL *)url;

- (instancetype)initWithImage:(nullable UIImage *)image andURL:(nullable NSURL *)url;
- (instancetype)initWithImage:(nullable UIImage *)image andMedia:(nullable Media *)media;

- (void)loadImage;
- (void)hideBars:(BOOL)hide animated:(BOOL)animated;
- (void)centerImage;

+ (BOOL)isUrlSupported:(NSURL *)url;

@end
NS_ASSUME_NONNULL_END
