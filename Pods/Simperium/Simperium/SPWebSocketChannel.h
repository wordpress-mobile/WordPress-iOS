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

@interface SPWebSocketChannel : NSObject

@property (nonatomic, weak) SPWebSocketInterface *webSocketManager;
@property (nonatomic, strong) NSMutableArray *indexArray;
@property (nonatomic, copy) NSString *nextMark;
@property (nonatomic, copy) NSString *pendingLastChangeSignature;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *remoteName;
@property (nonatomic, assign) int number;
@property (nonatomic, assign) BOOL started;

+ (void)setNetworkActivityIndicatorEnabled:(BOOL)enabled;

- (void)requestVersions:(int)numVersions object:(id<SPDiffable>)object;
- (void)requestLatestVersionsForBucket:(SPBucket *)bucket;
- (void)sendObjectDeletion:(id<SPDiffable>)object;
- (void)sendObjectChanges:(id<SPDiffable>)object;
- (void)sendBucketStatus:(SPBucket *)bucket;
- (void)removeAllBucketObjects:(SPBucket *)bucket;
- (void)shareObject:(id<SPDiffable>)object withEmail:(NSString *)email;
- (void)handleAuthResponse:(NSString *)responseString bucket:(SPBucket *)bucket;
- (void)handleRemoteChanges:(NSArray *)changes bucket:(SPBucket *)bucket;
- (void)handleIndexResponse:(NSString *)responseString bucket:(SPBucket *)bucket;
- (void)handleVersionResponse:(NSString *)responseString bucket:(SPBucket *)bucket;
- (void)startProcessingChangesForBucket:(SPBucket *)bucket;

+ (instancetype)channelWithSimperium:(Simperium *)s clientID:(NSString *)clientID;

@end
