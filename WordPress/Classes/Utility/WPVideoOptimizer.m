//
//  WPVideoOptimizer.m
//  WordPress
//
//  Created by Sérgio Estêvão on 31/05/2014.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPVideoOptimizer.h"
#import <AVFoundation/AVFoundation.h>

static NSString * const EnableVideoOptimizationDefaultsKey = @"WPEnableVideoOptimization";
static NSString * const PermanentVideoOptimizationDecisionTakenDefaultsKey = @"WPPermanentVideoOptimizationDecisionTaken";

static long long VideoMaxSize = 1024 * 1024 * 20;

@implementation WPVideoOptimizer

+ (BOOL)shouldOptimizeVideos
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:EnableVideoOptimizationDefaultsKey];
}

+ (void)setShouldOptimizeVideos:(BOOL)optimize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:optimize forKey:EnableVideoOptimizationDefaultsKey];
    [defaults synchronize];
}

+ (BOOL)isPermanentVideoOptimizationDecisionTaken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:PermanentVideoOptimizationDecisionTakenDefaultsKey];
}

+ (void)setPermanentVideoOptimizationDecisionTaken:(BOOL)optimize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:optimize forKey:PermanentVideoOptimizationDecisionTakenDefaultsKey];
    [defaults synchronize];
}


+ (BOOL)isAssetTooLarge:(ALAsset*)asset
{
    return [asset.defaultRepresentation size] > VideoMaxSize;
}

-(void)optimizeAsset:(ALAsset*)originalAsset resize:(BOOL) resize toPath:(NSString *)videoPath withHandler:(void (^)(NSError* error))handler
{
    ALAssetRepresentation* representation=originalAsset.defaultRepresentation;
    AVAsset * asset = [AVURLAsset URLAssetWithURL:representation.url options:nil];
    
    NSString * presetName = AVAssetExportPresetPassthrough;

    if ([[self class] shouldOptimizeVideos] || resize){
        presetName = AVAssetExportPresetMediumQuality;
    }
    
    AVAssetExportSession* session=[AVAssetExportSession exportSessionWithAsset:asset presetName:presetName];

    session.outputFileType = representation.UTI;
    session.shouldOptimizeForNetworkUse = YES;

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
