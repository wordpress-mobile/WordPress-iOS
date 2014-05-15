#import <Foundation/Foundation.h>
#import "Media.h"

@interface WPMediaSizing : NSObject

+ (MediaResize)mediaResizePreference;
+ (UIImage *)correctlySizedImage:(UIImage *)fullResolutionImage forBlogDimensions:(NSDictionary *)dimensions;

@end
