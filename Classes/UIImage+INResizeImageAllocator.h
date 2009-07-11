#import <Foundation/Foundation.h>

@interface UIImage (INResizeImageAllocator)

+ (UIImage *)imageWithImage : (UIImage *)image scaledToSize : (CGSize)newSize;
- (UIImage *)scaleImageToSize:(CGSize)newSize;

@end
