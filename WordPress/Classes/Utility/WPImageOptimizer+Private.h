#import "WPImageOptimizer.h"

@interface WPImageOptimizer (Private)

/**
 Returns the data from a given asset representation without processing it.
 */
- (NSData *)rawDataFromAssetRepresentation:(ALAssetRepresentation *)representation  stripGeoLocation:(BOOL) stripGeoLocation;

/**
 Returns the optimized data from a given asset representation.
 
 The image is read, scaled down, and saved with a lower quality setting.
 */
- (NSData *)resizedDataFromAssetRepresentation:(ALAssetRepresentation *)representation fittingSize:(CGSize)targetSize  stripGeoLocation:(BOOL) stripGeoLocation;

/**
 Returns the image (including edits and cropping) for the given representation.
 */
- (CGImageRef)newImageFromAssetRepresentation:(ALAssetRepresentation *)representation;

/**
 Returns the image metadata and optionaly strips from it XMP, Orientation and GeoLocation tags
 */
- (NSDictionary *)metadataFromRepresentation:(ALAssetRepresentation *)representation
                                    stripXMP:(BOOL) stripXMP
                            stripOrientation:(BOOL) stripOrientation
                            stripGeoLocation:(BOOL) stripGeoLocation;

/**
 Returns data combining the provided image and metadata.
 
 @param image the image to include in the data.
 @param quality the desired compression quality. See kCGImageDestinationLossyCompressionQuality
 @param type the uniform type identifier (UTI) of the resulting image. See [ALAssetRepresentation UTI]
 @param metadata a dictionary including properties defined in [CGImageProperties Reference][//apple_ref/doc/uid/TP40005103]
 @return data with the combined image and metadata.
 */
- (NSData *)dataWithImage:(CGImageRef)image compressionQuality:(CGFloat)quality type:(NSString *)type andMetadata:(NSDictionary *)metadata;

@end
