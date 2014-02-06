//
//  SPWebSocket.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 1/10/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

typedef enum {
    SPWebSocketErrorsActivityTimeout = -42
} SPWebSocketErrors;


#pragma mark ====================================================================================
#pragma mark Simperium WebSocket Adapter
#pragma mark ====================================================================================

@interface SPWebSocket : NSObject

@property (nonatomic, assign, readwrite) NSTimeInterval				activityTimeout;
@property (nonatomic, weak,   readwrite) id<SRWebSocketDelegate>	delegate;
@property (nonatomic, assign, readonly)  SRReadyState				readyState;

- (id)initWithURLRequest:(NSURLRequest *)request;

- (void)open;
- (void)close;
- (void)send:(id)data;

@end
