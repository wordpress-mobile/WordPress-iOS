#import "WPImageOptimizer+Private.h"
#import "UIImage+Resize.h"
#import <ImageIO/ImageIO.h>

static const CGFloat CompressionQuality = 0.7;

@implementation WPImageOptimizer (Private)

- (NSData *)rawDataFromAssetRepresentation:(ALAssetRepresentation *)representation
                          stripGeoLocation:(BOOL) stripGeoLocation
                             convertToType:(NSString *)convertionType
{
    CGImageRef sourceImage = [self newImageFromAssetRepresentation:representation];
    NSDictionary *metadata = [self metadataFromRepresentation:representation 
                                                     stripXMP:NO
                                             stripOrientation:NO
                                             stripGeoLocation:stripGeoLocation];
    NSString *type = convertionType;
    if (!type){
        type = representation.UTI;
    }
    NSData *optimizedData = [self dataWithImage:sourceImage compressionQuality:1.0  type:type andMetadata:metadata];

    CGImageRelease(sourceImage);
    sourceImage = nil;

    return optimizedData;
}

- (NSData *)resizedDataFromAssetRepresentation:(ALAssetRepresentation *)representation
                                   fittingSize:(CGSize)targetSize
                              stripGeoLocation:(BOOL) stripGeoLocation
                                 convertToType:(NSString *)convertionType
{
    CGImageRef sourceImage = [self newImageFromAssetRepresentation:representation];
    CGImageRef resizedImage = [self resizedImageWithImage:sourceImage scale:representation.scale orientation:representation.orientation fittingSize:targetSize];
    NSDictionary *metadata = [self metadataFromRepresentation:representation
                                                     stripXMP:YES
                                             stripOrientation:YES
                                             stripGeoLocation:stripGeoLocation];
    NSString *type = convertionType;
    if (!type){
        type = representation.UTI;
    }
    NSData *imageData = [self dataWithImage:resizedImage compressionQuality:CompressionQuality type:type andMetadata:metadata];

    CGImageRelease(sourceImage);
    sourceImage = nil;

    return imageData;
}

- (CGImageRef)newImageFromAssetRepresentation:(ALAssetRepresentation *)representation
{
    CGImageRef fullResolutionImage = CGImageRetain(representation.fullResolutionImage);
    NSString *adjustmentXMP = [representation.metadata objectForKey:@"AdjustmentXMP"];

    NSData *adjustmentXMPData = [adjustmentXMP dataUsingEncoding:NSUTF8StringEncoding];
    NSError *__autoreleasing error = nil;
    CGRect extend = CGRectZero;
    extend.size = representation.dimensions;
    NSArray *filters = nil;
    if (adjustmentXMPData) {
        filters = [CIFilter filterArrayFromSerializedXMP:adjustmentXMPData inputImageExtent:extend error:&error];
    }
    if (filters) {
        CIImage *image = [CIImage imageWithCGImage:fullResolutionImage];
        CIContext *context = [CIContext contextWithOptions:nil];
        for (CIFilter *filter in filters) {
            [filter setValue:image forKey:kCIInputImageKey];
            image = [filter outputImage];
        }

        CGImageRelease(fullResolutionImage);
        fullResolutionImage = [context createCGImage:image fromRect:image.extent];
    }
    return fullResolutionImage;
}

- (CGImageRef)resizedImageWithImage:(CGImageRef)image scale:(CGFloat)scale orientation:(UIImageOrientation)orientation fittingSize:(CGSize)targetSize
{
    UIImage *originalImage = [UIImage imageWithCGImage:image scale:scale orientation:orientation];
    CGSize originalSize = originalImage.size;
    CGSize newSize = [self sizeForOriginalSize:originalSize fittingSize:targetSize];
    UIImage *resizedImage = [originalImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                                bounds:newSize
                                                  interpolationQuality:kCGInterpolationHigh];
    return resizedImage.CGImage;
}

- (NSDictionary *)metadataFromRepresentation:(ALAssetRepresentation *)representation
                                    stripXMP:(BOOL) stripXMP
                            stripOrientation:(BOOL) stripOrientation
                            stripGeoLocation:(BOOL) stripGeoLocation
{
    NSString * const orientationKey = @"Orientation";
    NSString * const xmpKey = @"AdjustmentXMP";

    NSMutableDictionary *metadata = [representation.metadata mutableCopy];
    
    if (stripXMP){
        // Remove XMP data since filters have already been applied to the image
        [metadata removeObjectForKey:xmpKey];
    }

    if (stripOrientation) {
        // Remove rotation data, since the image is already rotated
        [metadata removeObjectForKey:orientationKey];

        if (metadata[(NSString *)kCGImagePropertyTIFFDictionary]) {
            NSMutableDictionary *tiffMetadata = [metadata[(NSString *)kCGImagePropertyTIFFDictionary] mutableCopy];
            tiffMetadata[(NSString *)kCGImagePropertyTIFFOrientation] = @1;
            metadata[(NSString *)kCGImagePropertyTIFFDictionary] = [NSDictionary dictionaryWithDictionary:tiffMetadata];
        }
    }
    
    if (stripGeoLocation) {
        [metadata removeObjectForKey:(NSString *)kCGImagePropertyGPSDictionary];
    }

    return [NSDictionary dictionaryWithDictionary:metadata];
}

- (NSData *)dataWithImage:(CGImageRef)image
       compressionQuality:(CGFloat)quality 
                     type:(NSString *)type
              andMetadata:(NSDictionary *)metadata
{
    NSMutableData *destinationData = [NSMutableData data];

    NSDictionary *properties = @{(__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(quality)};

    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)destinationData, (__bridge CFStringRef)type, 1, NULL);
    NSAssert(destination != nil, @"Image destination can't be nil");
    if (!destination) {
        DDLogError(@"Image destination couldn't be created. Type: %@", type);
        return nil;
    }
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)properties);
    CGImageDestinationAddImage(destination, image, (__bridge CFDictionaryRef) metadata);
    if (!CGImageDestinationFinalize(destination)) {
        DDLogError(@"Image destination couldn't be written");
        // If finalize fails, the output of the image destination will not be valid
        destinationData = nil;
    }

    if (destination) {
        CFRelease(destination);
    }

    NSData *returnData;
    if (destinationData) {
        returnData = [NSData dataWithData:destinationData];
    }
    return returnData;
}

@end
