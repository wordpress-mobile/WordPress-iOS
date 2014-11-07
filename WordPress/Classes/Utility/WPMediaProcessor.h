#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

/**
 WPMediaProcessor handles a queue for processing Assets to files to be upload to the servers.
 
 The purpose is to keep the number of resize and reenconding happening in parallel to a number that the system
 can handle withoud crashing because of lack of memory. All the processing is done in background queue and returned on the main queue.
 */
@interface WPMediaProcessor : NSObject

+ (instancetype) sharedInstance;

- (void)processAsset:(ALAsset *)asset
              toFile:(NSString *)filePath
            resizing:(CGSize)targetSize
    stripGeoLocation:(BOOL)stripGeoLocation
   completionHandler:(void (^)(BOOL success, CGSize resultingSize, NSData *thumbnailData, NSError *error)) handler;

@end
