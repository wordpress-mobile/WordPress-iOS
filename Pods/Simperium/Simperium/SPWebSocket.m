//
//  SPWebSocket.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 1/10/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import "SPWebSocket.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

NSTimeInterval const SPWebSocketTimeoutInterval = 60;


#pragma mark ====================================================================================
#pragma mark SPWebSocket Private Methods
#pragma mark ====================================================================================

@interface SPWebSocket () <SRWebSocketDelegate>
@property (nonatomic, strong, readwrite) SRWebSocket	*webSocket;
@property (nonatomic, strong, readwrite) NSTimer		*timeoutTimer;
@end


#pragma mark ====================================================================================
#pragma mark SPWebSocket
#pragma mark ====================================================================================

@implementation SPWebSocket

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.timeoutTimer invalidate];
	self.webSocket.delegate = nil;
}

- (id)initWithURLRequest:(NSURLRequest *)request
{
	if ((self = [super init])) {
		self.webSocket			= [[SRWebSocket alloc] initWithURLRequest:request];
		self.webSocket.delegate	= self;
		
		self.activityTimeout	= SPWebSocketTimeoutInterval;
		
#if TARGET_OS_IPHONE
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(handleBackgroundNote:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[nc addObserver:self selector:@selector(handleForegroundNote:) name:UIApplicationWillEnterForegroundNotification object:nil];
#endif
	}
	return self;
}

- (void)open {
	[self.webSocket open];
}

- (void)close {
	[self invalidateTimeoutTimer];
	[self.webSocket close];
}

- (void)send:(id)data {
	[self.webSocket send:data];
}

- (SRReadyState)readyState {
	return self.webSocket.readyState;
}


#pragma mark ====================================================================================
#pragma mark NSTimer Helpers
#pragma mark ====================================================================================

- (void)resetTimeoutTimer {
	[self.timeoutTimer invalidate];
	self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.activityTimeout target:self selector:@selector(handleTimeout:) userInfo:nil repeats:NO];
}

- (void)invalidateTimeoutTimer {
	[self.timeoutTimer invalidate];
	self.timeoutTimer = nil;
}

- (void)handleTimeout:(NSTimer *)timer {
	self.webSocket.delegate = nil;
	[self.webSocket close];
	
	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"Activity Timeout"};
	NSError* error = [NSError errorWithDomain:SRWebSocketErrorDomain code:SPWebSocketErrorsActivityTimeout userInfo:userInfo];
	[self.delegate webSocket:(SRWebSocket*)error didFailWithError:error];
}


#pragma mark ====================================================================================
#pragma mark SRWebSocketDelegate Methods
#pragma mark ====================================================================================

- (void)webSocketDidOpen:(SRWebSocket *)theWebSocket {
	[self resetTimeoutTimer];
	[self.delegate webSocketDidOpen:(SRWebSocket*)self];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
	[self resetTimeoutTimer];
	[self.delegate webSocket:(SRWebSocket*)self didReceiveMessage:message];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	[self invalidateTimeoutTimer];
	[self.delegate webSocket:(SRWebSocket*)self didFailWithError:error];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
	[self invalidateTimeoutTimer];
	[self.delegate webSocket:(SRWebSocket*)self didCloseWithCode:code reason:reason wasClean:wasClean];
}


#pragma mark ====================================================================================
#pragma mark iOS Background/Foreground Helpers
#pragma mark ====================================================================================

- (void)handleBackgroundNote:(NSNotification *)note {
	[self invalidateTimeoutTimer];
}

- (void)handleForegroundNote:(NSNotification *)note {
	[self resetTimeoutTimer];
}

@end
