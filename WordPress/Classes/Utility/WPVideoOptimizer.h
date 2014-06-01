//
//  WPVideoOptimizer.h
//  WordPress
//
//  Created by Sérgio Estêvão on 31/05/2014.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface WPVideoOptimizer : NSObject

-(void)optimizeAsset:(ALAsset*)asset toPath:(NSString *)videoPath withHandler:(void (^)(NSError* error))handler;

@end
