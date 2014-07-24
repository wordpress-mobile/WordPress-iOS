//
//  WPWebSnapshotWorker.h
//  WordPress
//
//  Created by Josh Avant on 7/23/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WPWebSnapshotRequest;

typedef NS_ENUM(NSUInteger, WPWebSnapshotWorkerStatus) {
    WPWebSnapshotWorkerStatusUnknown = 0,
    WPWebSnapshotWorkerStatusReady,
    WPWebSnapshotWorkerStatusExecuting
};

typedef void (^WPWebSnapshotWorkerCompletionHandler)(UIView *view, NSURL *url);

@interface WPWebSnapshotWorker : NSObject

@property (nonatomic, readonly) WPWebSnapshotWorkerStatus status;

- (void)startSnapshotWithRequest:(WPWebSnapshotRequest *)snapshotRequest completionHandler:(WPWebSnapshotWorkerCompletionHandler)completionHandler;

@end
