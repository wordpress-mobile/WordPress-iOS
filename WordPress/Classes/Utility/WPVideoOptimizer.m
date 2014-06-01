//
//  WPVideoOptimizer.m
//  WordPress
//
//  Created by Sérgio Estêvão on 31/05/2014.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPVideoOptimizer.h"
#import <AVFoundation/AVFoundation.h>


@implementation WPVideoOptimizer

-(void)optimizeAsset:(ALAsset*)asset toPath:(NSString *)videoPath withHandler:(void (^)(NSError* error))handler
{
    AVAssetExportSession* session=nil;
    ALAssetRepresentation* representation=asset.defaultRepresentation;
    session=[AVAssetExportSession exportSessionWithAsset:[AVURLAsset URLAssetWithURL:representation.url options:nil] presetName:AVAssetExportPresetPassthrough];
    //session.outputFileType=AVFileTypeQuickTimeMovie;
    session.outputFileType = representation.UTI;
    session.outputURL=[NSURL fileURLWithPath:videoPath];
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status!=AVAssetExportSessionStatusCompleted){
            NSError* error=session.error;
            handler(error);
            return;
        }
        handler(nil);
    }];
}

@end
