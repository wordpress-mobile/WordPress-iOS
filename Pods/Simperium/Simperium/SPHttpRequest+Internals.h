//
//  SPHttpRequest+Internals.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 10/21/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPHttpRequest.h"



#pragma mark ====================================================================================
#pragma mark SPHttpRequest
#pragma mark ====================================================================================

@interface SPHttpRequest (Internals)
@property (nonatomic, weak, readwrite) SPHttpRequestQueue *httpRequestQueue;
- (void)begin;
- (void)stop;
@end
