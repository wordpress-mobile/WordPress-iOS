#import "WPImageOptimizer.h"
#import "WPImageOptimizer+Private.h"

@implementation WPImageOptimizer

- (NSData *)rawDataFromAsset:(ALAsset *)asset
            stripGeoLocation:(BOOL) stripGeoLocation
               convertToType:(NSString *)type
{
    ALAssetRepresentation *representation = asset.defaultRepresentation;
    return [self rawDataFromAssetRepresentation:representation
                               stripGeoLocation:stripGeoLocation
                                  convertToType:type];
}

- (NSData *)optimizedDataFromAsset:(ALAsset *)asset
                       fittingSize:(CGSize)targetSize
                  stripGeoLocation:(BOOL) stripGeoLocation
                     convertToType:(NSString *)type
{
    ALAssetRepresentation *representation = asset.defaultRepresentation;
    // If it's an asset from a shared photo stream it's image may not be available
    if (!representation) {
        return nil;
    }
    // Can't optimize videos, so only try if asset is a photo
    // We can't resize an image to 0 height 0 width (there would be nothing to draw) so treat this as requesting the original image size by convention. 
    BOOL isImage = [[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypePhoto];
    if (CGSizeEqualToSize(targetSize, CGSizeZero) || !isImage) {
        return [self rawDataFromAssetRepresentation:representation stripGeoLocation:stripGeoLocation convertToType:type];
    }
    return [self resizedDataFromAssetRepresentation:representation
                                        fittingSize:targetSize
                                   stripGeoLocation:stripGeoLocation
                                      convertToType:type];
}

- (CGSize)sizeForOriginalSize:(CGSize)originalSize fittingSize:(CGSize)targetSize
{
    CGFloat widthRatio = MIN(targetSize.width, originalSize.width) / originalSize.width;
    CGFloat heightRatio = MIN(targetSize.height, originalSize.height) / originalSize.height;
    CGFloat ratio = MIN(widthRatio, heightRatio);
    return CGSizeMake(round(ratio * originalSize.width), round(ratio * originalSize.height));
}

@end
