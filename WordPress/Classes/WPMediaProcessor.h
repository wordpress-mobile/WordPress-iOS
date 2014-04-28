#import <Foundation/Foundation.h>
#import "Media.h"

@class ALAsset;

@interface WPMediaProcessor : NSObject

- (void)processImage:(UIImage *)theImage media:(Media *)imageMedia metadata:(NSDictionary *)metadata;
- (UIImage *)resizeImage:(UIImage *)original toSize:(CGSize)newSize;
- (NSDictionary *)metadataForAsset:(ALAsset *)asset enableGeolocation:(BOOL)enableGeolocation;

@end
