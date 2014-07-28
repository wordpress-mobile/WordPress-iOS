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

@property (nonatomic) NSURLRequest *urlRequest;
@property (nonatomic) CGSize snapshotSize;
@property (nonatomic) NSString *didFinishJavascript;
@property (nonatomic, copy) WPWebSnapshotterSnapshotCompletionHandler callback;

+ (WPWebSnapshotRequest *)snapshotRequestWithURLRequest:(NSURLRequest *)urlRequest
                                           snapshotSize:(CGSize)snapshotSize
                                    didFinishJavascript:(NSString *)javascript
                                      completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler;

@end
