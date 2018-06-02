#import <UIKit/UIKit.h>

@import Photos;
@import WPMediaPicker;

@class Media;

@interface WPImageViewController : UIViewController

@property (nonatomic, readonly) id<WPMediaAsset> mediaAsset;
@property (nonatomic, assign) BOOL shouldDismissWithGestures;

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithMedia:(Media *)media;
- (instancetype)initWithAsset:(PHAsset *)asset;
- (instancetype)initWithGifData:(NSData *)data;

- (instancetype)initWithImage:(UIImage *)image andURL:(NSURL *)url;
- (instancetype)initWithImage:(UIImage *)image andMedia:(Media *)media;

- (void)loadImage;
- (void)hideBars:(BOOL)hide animated:(BOOL)animated;
- (void)centerImage;

+ (BOOL)isUrlSupported:(NSURL *)url;

@end
