#import <UIKit/UIKit.h>

@class Media;

@interface WPImageViewController : UIViewController

@property (nonatomic, weak) NSNumber *index;

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithMedia:(Media *)media;
- (instancetype)initForGallery:(NSURL *)url andIndex:(NSNumber *)index;

- (instancetype)initWithImage:(UIImage *)image andURL:(NSURL *)url;
- (instancetype)initWithImage:(UIImage *)image andMedia:(Media *)media;


- (void)loadImage;
- (void)hideBars:(BOOL)hide animated:(BOOL)animated;
- (void)centerImage;

+ (BOOL)isUrlSupported:(NSURL *)url;

@end
