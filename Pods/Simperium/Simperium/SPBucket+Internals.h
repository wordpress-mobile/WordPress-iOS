//
//  SPBucket+Internals.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 12/10/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPBucket.h"



typedef void (^SPBucketForceSyncCompletion)(BOOL signatureUpdated);

#pragma mark ====================================================================================
#pragma mark SPBucket: Private Methods
#pragma mark ====================================================================================

@interface SPBucket ()

@property (nonatomic,   copy) NSString						*name;
@property (nonatomic,   copy) NSString						*remoteName;
@property (nonatomic,   copy) NSString						*instanceLabel;
@property (nonatomic,   copy) NSString						*lastChangeSignature;
@property (nonatomic, assign) BOOL							exposeNamespace;
@property (nonatomic,   copy) NSString						*localNamespace;
@property (nonatomic,   weak) id<SPStorageProvider>			storage;
@property (nonatomic, strong) id<SPNetworkInterface>		network;
@property (nonatomic, strong) SPDiffer						*differ;
@property (nonatomic, strong) SPSchema						*schema;
@property (nonatomic, strong) SPRelationshipResolver		*relationshipResolver;
@property (nonatomic, strong) SPChangeProcessor				*changeProcessor;
@property (nonatomic, strong) SPIndexProcessor				*indexProcessor;
@property (nonatomic, strong) dispatch_queue_t				processorQueue;
@property (nonatomic,   copy) SPBucketForceSyncCompletion	forceSyncCompletion;
@property (nonatomic,   copy) NSString						*forceSyncSignature;

- (id)initWithSchema:(SPSchema *)aSchema
             storage:(id<SPStorageProvider>)aStorage
	networkInterface:(id<SPNetworkInterface>)netInterface
relationshipResolver:(SPRelationshipResolver *)resolver
               label:(NSString *)label
		  remoteName:(NSString *)remoteName
            clientID:(NSString *)clientID;
- (void)validateObjects;
- (void)unloadAllObjects;
- (void)resolvePendingRelationshipsToKeys:(NSSet *)keys;
- (void)forceSyncWithCompletion:(SPBucketForceSyncCompletion)completion;
- (BOOL)isForceSyncPending;
- (void)signalForceSyncComplete;
- (NSDictionary*)exportStatus;

@end
