//
//  WPWebSnapshotRequest.m
//  WordPress
//
//  Created by Josh Avant on 7/24/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPWebSnapshotRequest.h"

@implementation WPWebSnapshotRequest

+ (WPWebSnapshotRequest *)snapshotRequestWithURLRequest:(NSURLRequest *)urlRequest snapshotSize:(CGSize)snapshotSize completionHandler:(WPWebSnapshotterSnapshotCompletionHandler)completionHandler
{
    WPWebSnapshotRequest *request = [[WPWebSnapshotRequest alloc] init];
    request.urlRequest = urlRequest;
    request.snapshotSize = snapshotSize;
    request.callback = completionHandler;
    
    return request;
}

@end
