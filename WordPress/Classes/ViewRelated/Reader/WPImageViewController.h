#import <UIKit/UIKit.h>

@class Media;

@interface WPImageViewController : UIViewController

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithMedia:(Media *)media;

- (instancetype)initWithImage:(UIImage *)image andURL:(NSURL *)url;
- (instancetype)initWithImage:(UIImage *)image andMedia:(Media *)media;

- (void)loadImage;
- (void)hideBars:(BOOL)hide animated:(BOOL)animated;
- (void)centerImage;

+ (BOOL)isUrlSupported:(NSURL *)url;

@end
