//
//  WPWebSnapshotRequest.h
//  WordPress
//
//  Created by Josh Avant on 7/24/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WPWebSnapshotter.h"

@interface WPWebSnapshotRequest : NSObject

@property (nonatomic) NSURL *snapshotURL;
@property (nonatomic) CGSize canvasSize;
@property (nonatomic, copy) WPWebSnapshotterSnapshotCompletionHandler callback;

+ (WPWebSnapshotRequest *)snapshotRequestWithURL:(NSURL *)url canvasSize:(CGSize)canvasSize completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler;

@end
