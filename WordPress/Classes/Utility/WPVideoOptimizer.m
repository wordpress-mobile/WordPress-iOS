//
//  WPVideoOptimizer.m
//  WordPress
//
//  Created by Sérgio Estêvão on 31/05/2014.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPVideoOptimizer.h"
#import <AVFoundation/AVFoundation.h>

static NSString * const DisableVideoOptimizationDefaultsKey = @"WPDisableVideoOptimization";
static long long VideoMaxSize = 1024 * 1024 * 20;

@implementation WPVideoOptimizer

+ (BOOL)shouldOptimizeVideos
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return ![defaults boolForKey:DisableVideoOptimizationDefaultsKey];
}

+ (void)setShouldOptimizeVideos:(BOOL)optimize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:!optimize forKey:DisableVideoOptimizationDefaultsKey];
    [defaults synchronize];
}


+ (BOOL)isAssetTooLarge:(ALAsset*)asset
{
    return [asset.defaultRepresentation size] > VideoMaxSize;
}

-(void)optimizeAsset:(ALAsset*)asset toPath:(NSString *)videoPath withHandler:(void (^)(NSError* error))handler
{
    NSString * presetName = AVAssetExportPresetPassthrough;
    ALAssetRepresentation* representation=asset.defaultRepresentation;
    if ([[self class] shouldOptimizeVideos] && [[self class] isAssetTooLarge:asset]){
        presetName = AVAssetExportPresetMediumQuality;
    }
    AVAssetExportSession* session=[AVAssetExportSession exportSessionWithAsset:[AVURLAsset URLAssetWithURL:representation.url options:nil] presetName:presetName];
    session.outputFileType = representation.UTI;
    session.outputURL=[NSURL fileURLWithPath:videoPath];
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status!=AVAssetExportSessionStatusCompleted){
            NSError* error=session.error;
            if (handler){
                handler(error);
            }
            return;
        }
        if (handler){
            handler(nil);
        }
    }];
}

@end
