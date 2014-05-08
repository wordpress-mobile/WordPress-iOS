#import "WPImageOptimizer.h"

@interface WPImageOptimizer (Private)

/**
 Returns the data from a given asset representation without processing it.
 */
- (NSData *)rawDataFromAssetRepresentation:(ALAssetRepresentation *)representation;

/**
 Returns the optimized data from a given asset representation.
 
 The image is read, scaled down, and saved with a lower quality setting.
 */
- (NSData *)optimizedDataFromAssetRepresentation:(ALAssetRepresentation *)representation;

/**
 Returns the image (including edits and cropping) for the given representation.
 */
- (CGImageRef)imageFromAssetRepresentation:(ALAssetRepresentation *)representation;

/**
 Returns a scaled down image.
 */
- (CGImageRef)resizedImageWithImage:(CGImageRef)image;

/**
 Returns a scaled down size that fits the limits.
 */
- (CGSize)sizeWithinLimitsForSize:(CGSize)originalSize;

/**
 Returns data combining the provided image and metadata.
 
 @param image the image to include in the data.
 @param type the uniform type identifier (UTI) of the resulting image. See [ALAssetRepresentation UTI]
 @param metadata a dictionary including properties defined in [CGImageProperties Reference][//apple_ref/doc/uid/TP40005103]
 @return data with the combined image and metadata.
 */
- (NSData *)dataWithImage:(CGImageRef)image type:(NSString *)type andMetadata:(NSDictionary *)metadata;


@end
