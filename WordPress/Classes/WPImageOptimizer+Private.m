#import "WPImageOptimizer+Private.h"
#import "UIImage+Resize.h"

#import <ImageIO/ImageIO.h>

static CGSize SizeLimit = { 2048, 2048 };
static CGFloat CompressionQuality = 0.7;

@implementation WPImageOptimizer (Private)

- (NSData *)rawDataFromAssetRepresentation:(ALAssetRepresentation *)representation {
    CGImageRef sourceImage = [self imageFromAssetRepresentation:representation];
    NSDictionary *metadata = representation.metadata;
    NSString *type = representation.UTI;
    NSData *optimizedData = [self dataWithImage:sourceImage type:type andMetadata:metadata];
    return optimizedData;
}

- (NSData *)optimizedDataFromAssetRepresentation:(ALAssetRepresentation *)representation {
    CGImageRef sourceImage = [self imageFromAssetRepresentation:representation];
    CGImageRef resizedImage = [self resizedImageWithImage:sourceImage];
    NSDictionary *metadata = representation.metadata;
    NSString *type = representation.UTI;
    NSData *optimizedData = [self dataWithImage:resizedImage type:type andMetadata:metadata];
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

- (CGImageRef)resizedImageWithImage:(CGImageRef)image {
    UIImage *originalImage = [UIImage imageWithCGImage:image];
    CGSize originalSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
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

- (NSData *)dataWithImage:(CGImageRef)image type:(NSString *)type andMetadata:(NSDictionary *)metadata {
    NSMutableData *destinationData = [NSMutableData data];

    NSDictionary *properties = @{(__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(CompressionQuality)};

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
