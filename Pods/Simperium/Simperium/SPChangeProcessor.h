//
//  SPChangeProcessor.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-15.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPProcessorNotificationNames.h"


@class SPBucket;

#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

typedef void(^SPChangeEnumerationBlockType)(NSDictionary *change, BOOL *stop);

extern NSString * const CH_KEY;
extern NSString * const CH_ADD;
extern NSString * const CH_REMOVE;
extern NSString * const CH_MODIFY;
extern NSString * const CH_OPERATION;
extern NSString * const CH_VALUE;
extern NSString * const CH_START_VERSION;
extern NSString * const CH_END_VERSION;
extern NSString * const CH_LOCAL_ID;


#pragma mark ====================================================================================
#pragma mark SPChangeProcessor
#pragma mark ====================================================================================

@interface SPChangeProcessor : NSObject

@property (nonatomic, strong, readonly) NSString	*label;
@property (nonatomic, assign, readonly) int			numChangesPending;
@property (nonatomic, assign, readonly) int			numKeysForObjectsWithMoreChanges;

- (id)initWithLabel:(NSString *)label;

- (void)reset;

- (void)processRemoteResponseForChanges:(NSArray *)changes bucket:(SPBucket *)bucket repostNeeded:(BOOL *)repostNeeded;
- (void)processRemoteChanges:(NSArray *)changes bucket:(SPBucket *)bucket clientID:(NSString *)clientID;

- (void)markObjectWithPendingChanges:(NSString *)key bucket:(SPBucket *)bucket;
- (NSDictionary *)processLocalObjectWithKey:(NSString *)key bucket:(SPBucket *)bucket;
- (NSDictionary *)processLocalDeletionWithKey:(NSString *)key;
- (NSDictionary *)processLocalBucketDeletion:(SPBucket *)bucket;

- (void)enumeratePendingChangesForBucket:(SPBucket *)bucket block:(SPChangeEnumerationBlockType)block;
- (void)enumerateQueuedChangesForBucket:(SPBucket *)bucket block:(SPChangeEnumerationBlockType)block;
- (void)enumerateRetryChangesForBucket:(SPBucket *)bucket block:(SPChangeEnumerationBlockType)block;

- (BOOL)hasReachedMaxPendings;
- (NSArray*)exportPendingChanges;

@end
