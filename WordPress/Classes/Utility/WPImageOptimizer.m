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
    ALAssetRepresentation *representation = asset.defaultRepresentation;
    // Can't optimize videos, so only try if asset is a photo
    BOOL isImage = [[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypePhoto];
    if (CGSizeEqualToSize(targetSize, CGSizeZero) || !isImage) {
        return [self rawDataFromAssetRepresentation:representation];
    }
    return [self resizedDataFromAssetRepresentation:representation fittingSize:targetSize];
}

@end
