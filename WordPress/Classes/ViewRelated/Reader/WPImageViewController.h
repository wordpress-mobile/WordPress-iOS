#import <UIKit/UIKit.h>

@interface WPImageViewController : UIViewController

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) UIImage *image;

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithImage:(UIImage *)image andURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
- (void)loadImage;
- (void)hideBars:(BOOL)hide animated:(BOOL)animated;
- (void)centerImage;

+ (BOOL)isUrlSupported:(NSURL *)url;

@end
