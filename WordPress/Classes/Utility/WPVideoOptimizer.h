//
//  WPVideoOptimizer.h
//  WordPress
//
//  Created by Sérgio Estêvão on 31/05/2014.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

/**
 WPVideoOptimizer reduces videos dimensions and quality for smaller file sizes and faster uploads.
 
 ## Usage
 
 ALAsset *asset = ...; // Obtain asset
 NSString *path = ...; // a path where to save the file
 WPVideoOptimizer *optimizer = [WPVideoOptimizer alloc] init];
 [optimizer optimizeAsset:asset toPath:path withHandler:handler];
 
 */
@interface WPVideoOptimizer : NSObject

/**
 Returns a Boolean value that indicates if WPVideoOptimizer will optimize videos.
 
 By default, it returns YES
 
 @return YES if optimization is enabled, NO otherwise
 @see setShouldOptimizeVideos:
 */
+ (BOOL)shouldOptimizeVideos;

/**
 Sets a flag indicating if WPVideoOptimizer will optimize videos.
 
 This value is stored in the application's NSUserDefaults with the key "WPDisableVideoOptimization".
 
 @param optimize a Boolean value indicating if WPVideoOptimizer should optimize images.
 @see shouldOptimizeVideos
 */
+ (void)setShouldOptimizeVideos:(BOOL)optimize;

/**
 Creates an optimized video file in a path from the provided asset.
 
 If shouldOptimizeVideos is YES, the video is read from the asset, scaled down and saved with a low quality factor.
 If shouldOptimizeVideos is NO, the video data is exported from the asset to the videoPath without changes in encoding.
 
 @param asset the ALAsset containing the image to optimize.
 @param videoPath the path to where the optimized video file will be created.
 @param handler a block function that is invoked when the optimization process is finished. If successfull the error argument will be nil otherwise it will return an error class with related information.
 */
-(void)optimizeAsset:(ALAsset*)asset toPath:(NSString *)videoPath withHandler:(void (^)(NSError* error))handler;

@end
