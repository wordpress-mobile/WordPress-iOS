#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface WPMediaMetadataExtractor : NSObject

+ (NSDictionary *)metadataForAsset:(ALAsset *)asset enableGeolocation:(BOOL)enableGeolocation;

@end
