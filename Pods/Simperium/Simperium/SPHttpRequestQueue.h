//
//  SPHttpRequestQueue.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 10/21/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>



@class SPHttpRequest;

#pragma mark ====================================================================================
#pragma mark SPHttpRequestQueue
#pragma mark ====================================================================================

@interface SPHttpRequestQueue : NSObject

@property (nonatomic, assign, readwrite) NSUInteger maxConcurrentConnections;
@property (nonatomic, assign, readonly)  NSSet *requests;
@property (nonatomic, assign, readwrite) BOOL enabled;

+ (instancetype)sharedInstance;

- (void)enqueueHttpRequest:(SPHttpRequest*)httpRequest;
- (void)dequeueHttpRequest:(SPHttpRequest*)httpRequest;

- (void)cancelAllRequest;
- (void)cancelRequestsWithURL:(NSURL *)url;

@end
