#import <Foundation/Foundation.h>
#import "Media.h"

@interface WPMediaSizing : NSObject

+ (MediaResize)mediaResizePreference;
+ (UIImage *)correctlySizedImage:(UIImage *)fullResolutionImage forBlogDimensions:(NSDictionary *)dimensions;

+ (UIImage *)resizeImage:(UIImage *)original toSize:(CGSize)newSize;
+ (CGSize)sizeForImage:(UIImage *)image mediaResize:(MediaResize)resize blogResizeDimensions:(NSDictionary *)dimensions;

@end
