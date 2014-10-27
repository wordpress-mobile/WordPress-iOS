#import "WPImageOptimizer.h"
#import "WPImageOptimizer+Private.h"

@implementation WPImageOptimizer

- (NSData *)rawDataFromAsset:(ALAsset *)asset
{
    ALAssetRepresentation *representation = asset.defaultRepresentation;
    return [self rawDataFromAssetRepresentation:representation];
}

- (NSData *)optimizedDataFromAsset:(ALAsset *)asset fittingSize:(CGSize)targetSize
{
    NSAssert(!CGSizeEqualToSize(CGSizeZero, targetSize), @"Cannot resize to 0x0.");

    ALAssetRepresentation *representation = asset.defaultRepresentation;
    // Can't optimize videos, so only try if asset is a photo
    // We can't resize an image to 0 height 0 width (there would be nothing to draw) so treat this as requesting the original image size by convention. 
    BOOL isImage = [[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypePhoto];
    if (CGSizeEqualToSize(targetSize, CGSizeZero) || !isImage) {
        return [self rawDataFromAssetRepresentation:representation];
    }
    return [self resizedDataFromAssetRepresentation:representation fittingSize:targetSize];
}

@end
