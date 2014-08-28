//
//  SPRelationshipResolver.m
//  Simperium
//
//  Created by Michael Johnston on 2012-08-22.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import "SPRelationshipResolver+Internals.h"
#import "SPDiffable.h"
#import "SPStorage.h"
#import "SPStorageProvider.h"
#import "JSONKit+Simperium.h"
#import "SPGhost.h"
#import "SPLogger.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSString * const SPRelationshipsPendingsLegacyKey    = @"SPPendingReferences";
static NSString * const SPRelationshipsPendingsNewKey       = @"SPRelationshipsPendingsNewKey";

static SPLogLevels logLevel                                 = SPLogLevelsInfo;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPRelationshipResolver()

@property (nonatomic, strong, readwrite) dispatch_queue_t   queue;
@property (nonatomic, strong, readwrite) NSHashTable        *pendingRelationships;

@end


#pragma mark ====================================================================================
#pragma mark SPRelationshipResolver
#pragma mark ====================================================================================

@implementation SPRelationshipResolver

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *label         = [@"com.simperium." stringByAppendingString:[[self class] description]];
        _queue                  = dispatch_queue_create([label cStringUsingEncoding:NSUTF8StringEncoding], NULL);
        _pendingRelationships   = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality];
    }
    
    return self;
}


#pragma mark - Public Methods

- (void)loadPendingRelationships:(id<SPStorageProvider>)storage {
    
    NSAssert([NSThread isMainThread],                                   @"Invalid Thread");
    NSAssert([storage conformsToProtocol:@protocol(SPStorageProvider)], @"Invalid Parameter");
    
    NSArray *legacy = [SPRelationship parseFromLegacyDictionary:storage.metadata[SPRelationshipsPendingsLegacyKey]];
    for (SPRelationship *relationship in legacy) {
        [self addPendingRelationship:relationship];
    }
    
    NSArray *pendings = [SPRelationship parseFromArray:storage.metadata[SPRelationshipsPendingsNewKey]];
    for (SPRelationship *relationship in pendings) {
        [self addPendingRelationship:relationship];
    }
    
    if (legacy.count) {
        [self saveWithStorage:storage];
    }
}

- (void)addPendingRelationship:(SPRelationship *)relationship {
    
    NSAssert([NSThread isMainThread],                                   @"Invalid Thread");
    NSAssert([relationship isKindOfClass:[SPRelationship class]],       @"Invalid Parameter");
        
    [self.pendingRelationships addObject:relationship];
}

- (void)resolvePendingRelationshipsForKey:(NSString *)simperiumKey
                               bucketName:(NSString *)bucketName
                                  storage:(id<SPStorageProvider>)storage {

    NSAssert([NSThread isMainThread],                                   @"Invalid Thread");
    NSAssert([simperiumKey isKindOfClass:[NSString class]],             @"Invalid Parameter");
    NSAssert([bucketName isKindOfClass:[NSString class]],               @"Invalid Parameter");
    NSAssert([storage conformsToProtocol:@protocol(SPStorageProvider)], @"Invalid Parameter");
    
    NSHashTable *relationships = [self relationshipsForKey:simperiumKey];
    if (relationships.count == 0) {
        return;
    }
    
    // Resolve the references but do it in the background
    dispatch_async(self.queue, ^{
        id<SPStorageProvider> threadSafeStorage = [storage threadSafeStorage];
        [threadSafeStorage beginSafeSection];
        
        NSHashTable *processed = [NSHashTable hashTableWithOptions:NSHashTableStrongMemory];
        
        for (SPRelationship *relationship in relationships) {

            // Infer the targetBucket: 'Legacy' descriptors didn't store the targetBucket
            NSString *targetBucket = relationship.targetBucket;
            
            if (!targetBucket) {
                if ([simperiumKey isEqualToString:relationship.targetKey]) {
                    targetBucket = bucketName;
                } else {
                    // Unhandled scenario: There is no way to determine the targetBucket!
                    SPLogError(@"Simperium Relationship Resolver cannot determine the targetBucket for relationship [%@] > [%@]",
                               relationship.sourceKey, relationship.targetKey);
                    continue;
                }
            }
            
            id<SPDiffable>sourceObject  = [threadSafeStorage objectForKey:relationship.sourceKey bucketName:relationship.sourceBucket];
            id<SPDiffable>targetObject  = [threadSafeStorage objectForKey:relationship.targetKey bucketName:targetBucket];
            
            if (!sourceObject || !targetObject) {
                continue;
            }

            SPLogVerbose(@"Simperium resolving pending reference for %@.%@=%@",
                         relationship.sourceKey, relationship.sourceAttribute, relationship.targetKey);
            
            [sourceObject simperiumSetValue:targetObject forKey:relationship.sourceAttribute];
            
            // Get the key reference into the ghost as well
            [sourceObject.ghost.memberData setObject:relationship.targetKey forKey:relationship.sourceAttribute];
            sourceObject.ghost.needsSave = YES;
            
            // Cleanup!
            [processed addObject:relationship];
        }
        
        if (processed.count) {
            [threadSafeStorage save];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [self removeRelationships:processed];
                    [self saveWithStorage:storage];
                }
            });
        }
        
        [threadSafeStorage finishSafeSection];
    });
}

- (void)saveWithStorage:(id<SPStorageProvider>)storage {
    
    NSAssert([storage conformsToProtocol:@protocol(SPStorageProvider)], @"Invalid Storage");
    NSAssert([NSThread isMainThread], @"Invalid Thread");
    
    NSMutableDictionary *metadata = [storage.metadata mutableCopy];
    
    // If there's already nothing there, save some CPU by not writing anything
    if (_pendingRelationships.count == 0 && !metadata[SPRelationshipsPendingsNewKey]) {
        return;
    }
    
    metadata[SPRelationshipsPendingsNewKey] = [SPRelationship serializeFromArray:_pendingRelationships.allObjects];
    [metadata removeObjectForKey:SPRelationshipsPendingsLegacyKey];
    storage.metadata = metadata;
    
    [storage save];
}

- (void)reset:(id<SPStorageProvider>)storage {
    
    [self.pendingRelationships removeAllObjects];
    [self saveWithStorage:storage];
    
    [storage save];
}


#pragma mark ====================================================================================
#pragma mark Private Helpers
#pragma mark ====================================================================================

- (NSHashTable *)relationshipsForKey:(NSString *)simperiumKey {
    
    NSAssert([NSThread isMainThread],                           @"Invalid Thread");
    NSAssert([simperiumKey isKindOfClass:[NSString class]],     @"Invalid Parameter");
    
    NSHashTable *relationships = [NSHashTable weakObjectsHashTable];
    for (SPRelationship *relationship in self.pendingRelationships) {
        if ([relationship.sourceKey isEqualToString:simperiumKey] || [relationship.targetKey isEqualToString:simperiumKey]) {
            [relationships addObject:relationship];
        }
    }
    
    return relationships;
}

- (void)removeRelationships:(NSHashTable *)relationships {
    
    NSAssert([NSThread isMainThread],                           @"Invalid Thread");
    NSAssert([relationships isKindOfClass:[NSHashTable class]], @"Invalid Parameter");
    
    [self.pendingRelationships minusHashTable:relationships];
}


#pragma mark ====================================================================================
#pragma mark Debug Helpers
#pragma mark ====================================================================================

#ifdef DEBUG

- (void)performBlock:(void (^)())block {
    dispatch_async(self.queue, block);
}

- (NSInteger)countPendingRelationships {
    return self.pendingRelationships.count;
}

- (NSInteger)countPendingRelationshipsWithSourceKey:(NSString *)sourceKey andTargetKey:(NSString *)targetKey {
    NSInteger count = 0;
    for (SPRelationship *relationship in self.pendingRelationships) {
        if ([relationship.sourceKey isEqualToString:sourceKey] && [relationship.targetKey isEqualToString:targetKey]) {
            ++count;
        }
    }
    
    return count;
}

#endif

@end
