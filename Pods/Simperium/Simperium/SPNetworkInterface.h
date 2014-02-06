//
//  SPNetworkProvider.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPDiffable.h"

@class SPBucket;

@protocol SPNetworkInterface <NSObject>
- (void)start:(SPBucket *)bucket;
- (void)stop:(SPBucket *)bucket;
- (void)resetBucketAndWait:(SPBucket *)bucket;
- (void)requestLatestVersionsForBucket:(SPBucket *)bucket;
- (void)requestVersions:(int)numVersions object:(id<SPDiffable>)object;
- (void)sendObjectDeletion:(id<SPDiffable>)object;
- (void)sendObjectChanges:(id<SPDiffable>)object;
- (void)sendLogMessage:(NSString*)logMessage;
- (void)removeAllBucketObjects:(SPBucket *)bucket;
- (void)shareObject:(id<SPDiffable>)object withEmail:(NSString *)email;
- (void)forceSyncBucket:(SPBucket *)bucket;
@end

extern NSString * const SPAuthenticationDidFail;
