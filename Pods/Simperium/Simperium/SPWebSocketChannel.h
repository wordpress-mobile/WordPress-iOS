//
//  SPWebSocketChannel.h
//  Simperium
//
//  Created by Michael Johnston on 12-08-09.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>



@class Simperium;
@class SPBucket;
@class SPWebSocketInterface;
@protocol SPDiffable;

#pragma mark ====================================================================================
#pragma mark SPWebSocketChannel
#pragma mark ====================================================================================

@interface SPWebSocketChannel : NSObject

@property (nonatomic,   weak) SPWebSocketInterface	*webSocketManager;
@property (nonatomic, strong) NSMutableArray		*indexArray;
@property (nonatomic,   copy) NSString				*nextMark;
@property (nonatomic,   copy) NSString				*pendingLastChangeSignature;
@property (nonatomic,   copy) NSString				*name;
@property (nonatomic,   copy) NSString				*remoteName;
@property (nonatomic, assign) int					number;
@property (nonatomic, assign) BOOL					authenticated;

// Object Versions
- (void)requestVersions:(int)numVersions object:(id<SPDiffable>)object;
- (void)requestLatestVersionsForBucket:(SPBucket *)bucket;

// Sending Object Changes
- (void)sendObjectDeletion:(id<SPDiffable>)object;
- (void)sendObjectChanges:(id<SPDiffable>)object;
- (void)shareObject:(id<SPDiffable>)object withEmail:(NSString *)email;

// Bucket Helpers
- (void)removeAllBucketObjects:(SPBucket *)bucket;

// Response Handlers
- (void)handleAuthResponse:(NSString *)responseString bucket:(SPBucket *)bucket;
- (void)handleRemoteChanges:(NSArray *)changes bucket:(SPBucket *)bucket;
- (void)handleIndexResponse:(NSString *)responseString bucket:(SPBucket *)bucket;
- (void)handleVersionResponse:(NSString *)responseString bucket:(SPBucket *)bucket;
- (void)handleOptions:(NSString *)options bucket:(SPBucket *)bucket;
- (void)handleIndexStatusRequest:(SPBucket *)bucket;

// Initialization
- (void)startProcessingChangesForBucket:(SPBucket *)bucket;

+ (instancetype)channelWithSimperium:(Simperium *)s;

@end
