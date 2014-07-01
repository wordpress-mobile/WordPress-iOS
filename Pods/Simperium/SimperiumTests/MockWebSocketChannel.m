//
//  MockWebSocketChannel.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 11/11/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "MockWebSocketChannel.h"



#pragma mark ====================================================================================
#pragma mark MockWebSocketChannel
#pragma mark ====================================================================================

@implementation MockWebSocketChannel

+ (void)load {
	NSAssert([SPWebSocketChannel respondsToSelector:@selector(registerClass:)], nil);
	[SPWebSocketChannel performSelector:@selector(registerClass:) withObject:[self class]];
}

@end
