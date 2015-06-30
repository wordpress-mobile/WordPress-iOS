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

-(void)optimizeAsset:(ALAsset*)originalAsset resize:(BOOL) resize toPath:(NSString *)videoPath withHandler:(void (^)(CGSize newDimensions, NSError* error))handler
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
                handler(CGSizeZero, error);
            }
            return;
        }
        if (handler){
            handler([[self class] resolutionForVideo:videoPath], nil);
        }
    }];
}

+ (CGSize) resolutionForVideo:(NSString *) videoPath {
    AVAssetTrack *videoTrack = nil;
    AVURLAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    
    CMFormatDescriptionRef formatDescription = NULL;
    NSArray *formatDescriptions = [videoTrack formatDescriptions];
    if ([formatDescriptions count] > 0){
        formatDescription = (__bridge CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
    }
    
    if ([videoTracks count] > 0)
        videoTrack = [videoTracks objectAtIndex:0];
    
    CGSize trackDimensions = {
        .width = 0.0,
        .height = 0.0,
    };
    trackDimensions = [videoTrack naturalSize];
    return trackDimensions;
}

@end