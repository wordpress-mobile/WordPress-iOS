//
//  MockWebSocketInterface.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 11/11/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPWebSocketInterface.h"
#import "MockWebSocketChannel.h"
#import "SPBucket.h"



@interface MockWebSocketInterface : SPWebSocketInterface

- (MockWebSocketChannel*)mockChannelForBucket:(SPBucket*)bucket;

- (NSSet*)mockSentMessages;
- (void)mockReceiveMessage:(NSString*)message;

@end
