#import <UIKit/UIKit.h>

@interface UIImageView (AFNetworkingExtra)

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
                success:(void (^)(UIImage *image))success
                failure:(void (^)(NSError *error))failure;

- (void)setImageWithURL:(NSURL *)url emptyCachePlaceholderImage:(UIImage *)emptyCachePlaceholderImage;

@end
