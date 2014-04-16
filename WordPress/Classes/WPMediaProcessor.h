#import <Foundation/Foundation.h>
#import "Media.h"

@interface WPMediaProcessor : NSObject

- (void)processImage:(UIImage *)theImage media:(Media *)imageMedia metadata:(NSDictionary *)metadata;
- (CGSize)sizeForImage:(UIImage *)image
           mediaResize:(MediaResize)resize
  blogResizeDimensions:(NSDictionary *)dimensions;
- (UIImage *)resizeImage:(UIImage *)original toSize:(CGSize)newSize;

@end
