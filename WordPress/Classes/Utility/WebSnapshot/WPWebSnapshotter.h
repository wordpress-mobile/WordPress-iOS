//
//  WPWebSnapshotter.h
//  WordPress
//
//  Created by Josh Avant on 7/23/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
@class  WPWebSnapshotWorker;

typedef void (^WPWebSnapshotterSnapshotCompletionHandler)(UIView *view);

// Captures UIView snapshots of URLs. Captured views are cached by instances of this class.

@interface WPWebSnapshotter : NSObject

@property (nonatomic, readonly) WPWebSnapshotWorker *worker;

// canvasSize's component values must not exceed the size of their corresponding axis within the
// app's key window
- (void)captureSnapshotOfURLRequest:(NSURLRequest *)urlRequest
                         canvasSize:(CGSize)canvasSize
                  completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler;

@end
