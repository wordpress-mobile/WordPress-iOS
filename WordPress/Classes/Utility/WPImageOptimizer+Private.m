#import "WPImageOptimizer+Private.h"
#import "UIImage+Resize.h"

#import <ImageIO/ImageIO.h>

static const CGSize SizeLimit = { 2048, 2048 };
static const CGFloat CompressionQuality = 0.7;

@implementation WPImageOptimizer (Private)

- (NSData *)rawDataFromAssetRepresentation:(ALAssetRepresentation *)representation {
    CGImageRef sourceImage = [self imageFromAssetRepresentation:representation];
    NSDictionary *metadata = representation.metadata;
    NSString *type = representation.UTI;
    NSData *optimizedData = [self dataWithImage:sourceImage compressionQuality:1.0  type:type andMetadata:metadata];
    return optimizedData;
}

- (NSData *)optimizedDataFromAssetRepresentation:(ALAssetRepresentation *)representation {
    CGImageRef sourceImage = [self imageFromAssetRepresentation:representation];
    CGImageRef resizedImage = [self resizedImageWithImage:sourceImage scale:representation.scale orientation:representation.orientation];
    NSDictionary *metadata = [self metadataFromRepresentation:representation];
    NSString *type = representation.UTI;
    NSData *optimizedData = [self dataWithImage:resizedImage compressionQuality:CompressionQuality type:type andMetadata:metadata];
    return optimizedData;
}

- (CGImageRef)imageFromAssetRepresentation:(ALAssetRepresentation *)representation {
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
    if (filters)
    {
        CIImage *image = [CIImage imageWithCGImage:fullResolutionImage];
        CIContext *context = [CIContext contextWithOptions:nil];
        for (CIFilter *filter in filters)
        {
            [filter setValue:image forKey:kCIInputImageKey];
            image = [filter outputImage];
        }

        CGImageRelease(fullResolutionImage);
        fullResolutionImage = [context createCGImage:image fromRect:image.extent];
    }
    return fullResolutionImage;
}

- (CGImageRef)resizedImageWithImage:(CGImageRef)image scale:(CGFloat)scale orientation:(UIImageOrientation)orientation {
    UIImage *originalImage = [UIImage imageWithCGImage:image scale:scale orientation:orientation];
    CGSize originalSize = originalImage.size;
    CGSize newSize = [self sizeWithinLimitsForSize:originalSize];
    UIImage *resizedImage = [originalImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                                bounds:newSize
                                                  interpolationQuality:kCGInterpolationHigh];
    return resizedImage.CGImage;
}

- (CGSize)sizeWithinLimitsForSize:(CGSize)originalSize {
    CGFloat widthRatio = MIN(SizeLimit.width, originalSize.width) / originalSize.width;
    CGFloat heightRatio = MIN(SizeLimit.height, originalSize.height) / originalSize.height;
    CGFloat ratio = MIN(widthRatio, heightRatio);
    return CGSizeMake(round(ratio * originalSize.width), round(ratio * originalSize.height));
}

- (NSDictionary *)metadataFromRepresentation:(ALAssetRepresentation *)representation {
    NSString * const orientationKey = @"Orientation";
    NSString * const xmpKey = @"AdjustmentXMP";
    NSString * const tiffKey = @"{TIFF}";

    NSMutableDictionary *metadata = [representation.metadata mutableCopy];

    // Remove XMP data since filters have already been applied to the image
    [metadata removeObjectForKey:xmpKey];

    // Remove rotation data, since the image is already rotated
    [metadata removeObjectForKey:orientationKey];

    if ([metadata objectForKey:tiffKey]) {
        NSMutableDictionary *tiffMetadata = [metadata[tiffKey] mutableCopy];
        [tiffMetadata setObject:@1 forKey:orientationKey];
        [metadata setObject:[NSDictionary dictionaryWithDictionary:tiffMetadata] forKey:tiffKey];
    }

    return [NSDictionary dictionaryWithDictionary:metadata];
}

- (NSData *)dataWithImage:(CGImageRef)image compressionQuality:(CGFloat)quality type:(NSString *)type andMetadata:(NSDictionary *)metadata {
    NSMutableData *destinationData = [NSMutableData data];

    NSDictionary *properties = @{(__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(quality)};

    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)destinationData, (__bridge CFStringRef)type, 1, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)properties);
    CGImageDestinationAddImage(destination, image, (__bridge CFDictionaryRef) metadata);
    if (!CGImageDestinationFinalize(destination)) {
        DDLogError(@"Image destination couldn't be written");
    }
    CFRelease(destination);

    return [NSData dataWithData:destinationData];
}

@end
