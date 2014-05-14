//
//  MockWebsocketInterface.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 11/11/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "MockWebSocketInterface.h"
#import "SRWebSocket.h"



#pragma mark ====================================================================================
#pragma mark SPWebSocketInterface: Exposing Private Methods
#pragma mark ====================================================================================

@interface SPWebSocketInterface()
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
- (void)authenticateChannel:(SPWebSocketChannel *)channel;
- (SPWebSocketChannel *)loadChannelForBucket:(SPBucket *)bucket;
- (SPWebSocketChannel *)channelForName:(NSString *)str;
- (void)startChannels;
@end


#pragma mark ====================================================================================
#pragma mark MockWebSocketInterface
#pragma mark ====================================================================================

@interface MockWebSocketInterface()
@property (nonatomic, strong, readwrite) NSMutableSet* mutableSentMessages;
@end


@implementation MockWebSocketInterface

+ (void)load {
	NSAssert([SPWebSocketInterface respondsToSelector:@selector(registerClass:)], nil);
	[SPWebSocketInterface performSelector:@selector(registerClass:) withObject:[self class]];
}

- (MockWebSocketChannel*)mockChannelForBucket:(SPBucket*)bucket {
	return (MockWebSocketChannel*)[super channelForName:bucket.name];
}

- (NSSet*)mockSentMessages {
	return self.mutableSentMessages;
}

- (void)mockReceiveMessage:(NSString*)message {
	[super webSocket:nil didReceiveMessage:message];
}


#pragma mark ====================================================================================
#pragma mark Overriden Methods
#pragma mark ====================================================================================

- (SPWebSocketChannel*)loadChannelForBucket:(SPBucket*)bucket {
	SPWebSocketChannel* channel = [super loadChannelForBucket:bucket];
	channel.webSocketManager = self;
	channel.authenticated = YES;
	return channel;
}

- (void)openWebSocket {
	// Do not open a SRWebSocket instance
}

- (BOOL)open {
	// The "WebSocket" is always open, for unit testing purposes
	return YES;
}

- (void)send:(NSString*)message {
	if (self.mutableSentMessages == nil) {
		self.mutableSentMessages = [NSMutableSet set];
	}
	
	[self.mutableSentMessages addObject:message];
}

@end
