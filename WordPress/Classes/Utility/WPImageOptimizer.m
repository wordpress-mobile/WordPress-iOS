#import "WPImageOptimizer.h"
#import "WPImageOptimizer+Private.h"

static NSString * const DisableImageOptimizationDefaultsKey = @"WPDisableImageOptimization";

@implementation WPImageOptimizer

+ (BOOL)shouldOptimizeImages {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return ![defaults boolForKey:DisableImageOptimizationDefaultsKey];
}

+ (void)setShouldOptimizeImages:(BOOL)optimize {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:!optimize forKey:DisableImageOptimizationDefaultsKey];
    [defaults synchronize];
}

- (NSData *)optimizedDataFromAsset:(ALAsset *)asset {
    ALAssetRepresentation *representation = asset.defaultRepresentation;
    // Can't optimize videos, so only try if asset is a photo
    BOOL isImage = [[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypePhoto];
    if (![[self class] shouldOptimizeImages] || !isImage) {
        return [self rawDataFromAssetRepresentation:representation];
    }
    return [self optimizedDataFromAssetRepresentation:representation];
}

@end
