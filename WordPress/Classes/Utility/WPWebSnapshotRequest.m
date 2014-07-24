//
//  WPWebSnapshotRequest.m
//  WordPress
//
//  Created by Josh Avant on 7/24/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPWebSnapshotRequest.h"

@implementation WPWebSnapshotRequest

+ (WPWebSnapshotRequest *)snapshotRequestWithURLRequest:(NSURLRequest *)urlRequest canvasSize:(CGSize)canvasSize completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler
{
    WPWebSnapshotRequest *request = [[WPWebSnapshotRequest alloc] init];
    request.urlRequest = urlRequest;
    request.canvasSize = canvasSize;
    request.callback = completionHandler;
    
    return request;
}

@end
