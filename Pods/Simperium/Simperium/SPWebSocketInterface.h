//
//  SPWebSocketManager
//  Simperium
//
//  Created by Michael Johnston on 12-08-06.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPNetworkInterface.h"



@class Simperium;
@class SPWebSocket;

#pragma mark ====================================================================================
#pragma mark SPWebSocketInterface
#pragma mark ====================================================================================

@interface SPWebSocketInterface : NSObject <SPNetworkInterface>

- (void)loadChannelsForBuckets:(NSDictionary *)bucketList;
- (void)send:(NSString *)message;

+ (instancetype)interfaceWithSimperium:(Simperium *)s;

@end
