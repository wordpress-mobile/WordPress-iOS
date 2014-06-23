#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

/**
 WPImageOptimizer reduces images dimensions and quality for smaller file sizes and faster uploads.

 ## Usage

    ALAsset *asset = ...; // Obtain asset
    WPImageOptimizer *optimizer = [WPImageOptimizer new];
    NSData *assetData = [optimizer optimizedDataFromAsset:asset];

 */
@interface WPImageOptimizer : NSObject
/**
 Returns a Boolean value that indicates if WPImageOptimizer will optimize images.
 
 By default, it returns YES

 @return YES if optimization is enabled, NO otherwise
 @see setShouldOptimizeImages:
 */
+ (BOOL)shouldOptimizeImages;

/**
 Sets a flag indicating if WPImageOptimizer will optimize images.
 
 This value is stored in the application's NSUserDefaults with the key "WPDisableImageOptimization".

 @param optimize a Boolean value indicating if WPImageOptimizer should optimize images.
 @see shouldOptimizeImages
 */
+ (void)setShouldOptimizeImages:(BOOL)optimize;

/**
 Returns optimized image data from the provided asset.
 
 If shouldOptimizeImages is YES, the image is read from the asset, scaled down and saved with a low quality factor (enough to considerably reduce file size without hurting perceived quality).
 If shouldOptimizeImages is NO, the image data is read from the asset and returned.
 
 @param asset the ALAsset containing the image to optimize.
 @return the optimized data
 */
- (NSData *)optimizedDataFromAsset:(ALAsset *)asset;
@end
