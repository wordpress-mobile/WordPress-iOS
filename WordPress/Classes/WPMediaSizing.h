#import <Foundation/Foundation.h>
#import "Media.h"

@interface WPMediaSizing : NSObject

+ (MediaResize)mediaResizePreference;
+ (CGSize)sizeForImage:(UIImage *)image
           mediaResize:(MediaResize)resize
  blogResizeDimensions:(NSDictionary *)dimensions;

@end
