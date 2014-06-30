//
//  SPRelationshipResolver.m
//  Simperium
//
//  Created by Michael Johnston on 2012-08-22.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import "SPRelationshipResolver.H"
#import "SPDiffable.h"
#import "SPStorage.h"
#import "SPStorageProvider.h"
#import "JSONKit+Simperium.h"
#import "SPGhost.h"
#import "SPLogger.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSString * const SPRelationshipsPathKey          = @"SPPathKey";
static NSString * const SPRelationshipsPathBucket       = @"SPPathBucket";
static NSString * const SPRelationshipsPathAttribute    = @"SPPathAttribute";
static NSString * const SPRelationshipsPendingsKey      = @"SPPendingReferences";

static SPLogLevels logLevel                             = SPLogLevelsInfo;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPRelationshipResolver()

@property (nonatomic, strong) NSMutableDictionary   *pendingRelationships;
@property (nonatomic, strong) dispatch_queue_t      queue;

@end


#pragma mark ====================================================================================
#pragma mark SPRelationshipResolver
#pragma mark ====================================================================================

@implementation SPRelationshipResolver

- (id)init {
    if ((self = [super init])) {
        NSString *queueLabel        = [@"com.simperium." stringByAppendingString:[[self class] description]];
        self.queue                  = dispatch_queue_create([queueLabel cStringUsingEncoding:NSUTF8StringEncoding], NULL);
        self.pendingRelationships   = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    return self;
}


- (void)writePendingReferences:(id<SPStorageProvider>)storage {
    NSDictionary *metadata = [storage metadata];

    // If there's already nothing there, save some CPU by not writing anything
    if ( self.pendingRelationships.count == 0 && metadata[SPRelationshipsPendingsKey] == nil ) {
        return;
    }
    
    NSMutableDictionary *updated = [metadata mutableCopy];
    updated[SPRelationshipsPendingsKey] = self.pendingRelationships;
    [storage setMetadata:updated];
}

- (void)loadPendingRelationships:(id<SPStorageProvider>)storage {
    // Load changes that didn't get a chance to send
	NSDictionary *pendingDict = storage.metadata[SPRelationshipsPendingsKey];
    for (NSString *key in [pendingDict allKeys]) {
        // Manually create mutable children
        self.pendingRelationships[key] = [pendingDict[key] mutableCopy];
    }
}


- (BOOL)hasPendingReferenceToKey:(NSString *)key {
    return self.pendingRelationships[key] != nil;
}

- (void)addPendingRelationshipToKey:(NSString *)key fromKey:(NSString *)fromKey bucketName:(NSString *)bucketName
                   attributeName:(NSString *)attributeName storage:(id<SPStorageProvider>)storage {
    if (key.length == 0) {
        SPLogWarn(@"Simperium warning: received empty pending reference to attribute %@", attributeName);
        return;
    }
    
    if (bucketName.length == 0) {
        SPLogWarn(@"Simperium warning: received pending reference to attribute %@ with empty bucket", attributeName);
        return;
    }
    
    NSDictionary *path = @{
        SPRelationshipsPathKey          : fromKey,
        SPRelationshipsPathBucket       : bucketName,
        SPRelationshipsPathAttribute    : attributeName
    };
    
    SPLogVerbose(@"Simperium adding pending reference from %@ (%@) to %@ (%@)", fromKey, attributeName, key, bucketName);
    
    // Check to see if any references are already being tracked for this entity
    NSMutableArray *paths = self.pendingRelationships[key];
    if (paths == nil) {
        paths = [NSMutableArray arrayWithCapacity:3];
        [self.pendingRelationships setObject:paths forKey:key];
    }
    [paths addObject:path];
    [self writePendingReferences:storage];
}

- (void)resolvePendingRelationshipsToKey:(NSString *)toKey bucketName:(NSString *)bucketName storage:(id<SPStorageProvider>)storage {
    // The passed entity is now synced, so check for any pending references to it that can now be resolved
    NSMutableArray *paths = self.pendingRelationships[toKey];
    if (paths == nil) {
        return;
    }
    
    // Resolve the references but do it in the background
    dispatch_async(self.queue, ^{
        id<SPStorageProvider> threadSafeStorage = [storage threadSafeStorage];
        [threadSafeStorage beginSafeSection];
        
        id<SPDiffable>toObject = [threadSafeStorage objectForKey:toKey bucketName:bucketName];
        
        if (!toObject) {
            SPLogError(@"Simperium error, tried to resolve reference to an object that doesn't exist yet (%@): %@", bucketName, toKey);
            [threadSafeStorage finishSafeSection];
            return;
        }

        for (NSDictionary *path in paths) {
            // There'd be no way to get the entityName here since there's no way to look at an instance's members
            // Get it from the "path" instead
            NSString *fromKey           = path[SPRelationshipsPathKey];
            NSString *fromBucketName    = path[SPRelationshipsPathBucket];
            NSString *attributeName     = path[SPRelationshipsPathAttribute];
            id<SPDiffable> fromObject   = [threadSafeStorage objectForKey:fromKey bucketName:fromBucketName];
            
            SPLogVerbose(@"Simperium resolving pending reference for %@.%@=%@", fromKey, attributeName, toKey);
            [fromObject simperiumSetValue:toObject forKey: attributeName];
            
            // Get the key reference into the ghost as well
            [fromObject.ghost.memberData setObject:toKey forKey: attributeName];
            fromObject.ghost.needsSave = YES;
        }
        
        [threadSafeStorage save];
        [threadSafeStorage finishSafeSection];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // All references to entity were resolved above, so remove it from the pending array
            [self.pendingRelationships removeObjectForKey:toKey];
            [self writePendingReferences:storage];
            
            // Expect the context to be saved elsewhere
            //[storage save];
        });
    });
}

- (void)reset:(id<SPStorageProvider>)storage {
    [self.pendingRelationships removeAllObjects];
    [self writePendingReferences:storage];
    [storage save];
}

@end
