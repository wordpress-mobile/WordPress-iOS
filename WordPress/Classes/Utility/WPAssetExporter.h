#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

extern NSString * const WPAssetExportErrorDomain;
extern const NSInteger WPAssetExportErrorCodeMissingAsset;

/**
 WPAssetExporter handles a queue for exporting ALAsset to files.
 
 The purpose is to keep the number of resize and reenconding happening in parallel to a number that the system
 can handle withoud crashing because of lack of memory. All the processing is done in background queue and returned on the main queue.
 */
@interface WPAssetExporter : NSObject

+ (instancetype) sharedInstance;

/** 
 Exports an asset to a file.
 
 @asset to export
 @filePath location to where the asset should be exported, this must be writable
 @targetSize the maximum resolution that the file can have after exporting.
 @stripGeoLocation if YES any geographic location existent on the metadata of the asset will be stripped
 @param handler on completion with success the asset will be saved to the filePath with the resultingSize and the thumbnailData
*/
- (void)exportAsset:(ALAsset *)asset
              toFile:(NSString *)filePath
            resizing:(CGSize)targetSize
    stripGeoLocation:(BOOL)stripGeoLocation
   completionHandler:(void (^)(BOOL success, CGSize resultingSize, NSData *thumbnailData, NSError *error)) handler;

@end
