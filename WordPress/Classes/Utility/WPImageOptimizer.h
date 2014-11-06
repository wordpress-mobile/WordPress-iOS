#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

/**
 WPImageOptimizer reduces images dimensions and quality for smaller file sizes and faster uploads.

 ## Usage

    ALAsset *asset = ...; // Obtain asset
    WPImageOptimizer *optimizer = [WPImageOptimizer new];
    CGSize size = CGSize(1024, 1024);
    NSData *assetData = [optimizer optimizedDataFromAsset:asset fittingSize:size];

 */
@interface WPImageOptimizer : NSObject

/**
 Returns a resized image data from the provided asset.
 
 The image is read from the asset, scaled down and saved with a low quality factor (enough to considerably reduce file size without hurting perceived quality).

 @param asset the ALAsset containing the image to optimize.
 @param targetSize the size the image shoul be resized to.  Passing CGSizeZero will by pass resizing logic and return the raw asset. 
 @param stripGeoLocation if YES the resulting data will be stripped of any GPS information from the original asset
 
 @return the optimized data
 */
- (NSData *)optimizedDataFromAsset:(ALAsset *)asset fittingSize:(CGSize)targetSize stripGeoLocation:(BOOL) stripGeoLocation;

/**
 Returns a resized image data from the provided asset.

 The image data is read from the asset and returned

 @param asset the ALAsset containing the image to optimize.
 @param stripGeoLocation if YES the resulting data will be stripped of any GPS information from the original asset
 
 @return the raw data
 */
- (NSData *)rawDataFromAsset:(ALAsset *)asset stripGeoLocation:(BOOL) stripGeoLocation;

@end
