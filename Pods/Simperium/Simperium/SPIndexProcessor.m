//
//  SPIndexProcessor.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-16.
//  Copyright (c) 2011 Simperium. All rights reserved.
//
//  Processes index data from the Simperium service

#import "Simperium.h"
#import "SPStorage.h"
#import "SPIndexProcessor.h"
#import "SPManagedObject.h"
#import "SPGhost.h"
#import "SPStorage.h"
#import "JSONKit+Simperium.h"
#import "SPLogger.h"
#import "SPBucket+Internals.h"
#import "SPDiffable.h"
#import "SPDiffer.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static SPLogLevels logLevel = SPLogLevelsInfo;
#define kBatchSize 50


#pragma mark ====================================================================================
#pragma mark SPIndexProcessor
#pragma mark ====================================================================================

@implementation SPIndexProcessor

- (id)init {
    if (self = [super init]) {
    }
    
    return self;
}


// Process an index of keys from the Simperium service for a particular bucket
- (void)processIndex:(NSArray *)indexArray bucket:(SPBucket *)bucket versionHandler:(void(^)(NSString *key, NSString *version))versionHandler  {
    // indexArray could have thousands of items; break it up into batches to manage memory use
    NSMutableDictionary *indexDict = [NSMutableDictionary dictionaryWithCapacity:[indexArray count]];
    NSInteger numBatches = 1 + [indexArray count] / kBatchSize;
    NSMutableArray *batchLists = [NSMutableArray arrayWithCapacity:numBatches];
    for (int i=0; i<numBatches; i++) {
        [batchLists addObject: [NSMutableArray arrayWithCapacity:kBatchSize]];
    }
    
    // Build the batches
    int currentBatch = 0;
    NSMutableArray *currentBatchList = [batchLists objectAtIndex:currentBatch];
    for (NSDictionary *dict in indexArray) {
        NSString *key = [dict objectForKey:@"id"];
        id version = [dict objectForKey:@"v"];
        
        // Map it for convenience
        [indexDict setObject:version forKey:key];
        
        // Put it in a batch (advancing to next batch if necessary)
        [currentBatchList addObject:key];
        if ([currentBatchList count] == kBatchSize) {
            currentBatchList = [batchLists objectAtIndex:++currentBatch];
        }
    }
    
    // Take this opportunity to check for any objects that exist locally but not remotely, and remove them
    // (this can happen after reindexing if the client missed some remote deletion changes)
	NSSet *remoteKeySet = [NSSet setWithArray:[indexDict allKeys]];
	[self reconcileLocalAndRemoteIndex:remoteKeySet bucket:bucket];
    
    // Process each batch while being efficient with memory and faulting
    id<SPStorageProvider> threadSafeStorage = [bucket.storage threadSafeStorage];
	[threadSafeStorage beginSafeSection];
	
    for (NSMutableArray *batchList in batchLists) {
        @autoreleasepool {
        // Batch fault the entities for efficiency
            NSDictionary *objects = [threadSafeStorage faultObjectsForKeys:batchList bucketName:bucket.name];
            
            for (NSString *key in batchList) {
                id version = [indexDict objectForKey: key];
                
                // Store versions as strings, but if they come off the wire as numbers, then handle that too
                if ([version isKindOfClass:[NSNumber class]])
                    version = [NSString stringWithFormat:@"%ld", (long)[version integerValue]];
                
                // Check to see if this entity already exists locally and is up to date
                id<SPDiffable> object = [objects objectForKey:key];
                if (object && object.ghost != nil && object.ghost.version != nil && [version isEqualToString:object.ghost.version])
                    continue;
                
                // Allow caller to use the key and version
                versionHandler(key, version);
            }
            
            // Refault to free up the memory
            [threadSafeStorage refaultObjects: [objects allValues]];
        }
    }
	
	[threadSafeStorage finishSafeSection];
}

- (void)reconcileLocalAndRemoteIndex:(NSSet *)remoteKeySet bucket:(SPBucket *)bucket {
	
	id<SPStorageProvider> threadSafeStorage = [bucket.storage threadSafeStorage];
	[threadSafeStorage beginCriticalSection];
	
    NSArray *localKeys = [threadSafeStorage objectKeysForBucketName:bucket.name];
    NSMutableSet *localKeySet = [NSMutableSet setWithArray:localKeys];
    [localKeySet minusSet:remoteKeySet];

    // If any objects exist locally but not remotely, get rid of them
    if (localKeySet.count > 0) {
        NSMutableSet *keysForDeletedObjects = [NSMutableSet setWithCapacity:[localKeySet count]];
        NSArray *objectsToDelete = [threadSafeStorage objectsForKeys:localKeySet bucketName:bucket.name];
        
        for (id<SPDiffable>objectToDelete in objectsToDelete) {
            NSString *key = [objectToDelete simperiumKey];
            
            // If the object has never synced, be careful not to delete it (it won't exist in the remote index yet)
            if ([[objectToDelete ghost] memberData] == nil) {
                SPLogWarn(@"Simperium found local object that doesn't exist remotely yet: %@ (%@)", key, bucket.name);
                continue;
            }
            [keysForDeletedObjects addObject:key];
            [threadSafeStorage deleteObject:objectToDelete];
        }
        SPLogVerbose(@"Simperium deleting %ld objects after re-indexing", (long)[keysForDeletedObjects count]);
        [threadSafeStorage save];
        
		dispatch_async(dispatch_get_main_queue(), ^{
			NSDictionary *userInfo = @{
			   @"bucketName"	: bucket.name,
			   @"keys"			: keysForDeletedObjects
			 };
			[[NSNotificationCenter defaultCenter] postNotificationName:ProcessorDidDeleteObjectKeysNotification object:bucket userInfo:userInfo];
		});
    }
	
	[threadSafeStorage finishCriticalSection];
}

// Process actual version data from the Simperium service for a particular bucket
- (void)processVersions:(NSArray *)versions bucket:(SPBucket *)bucket firstSync:(BOOL)firstSync changeHandler:(void(^)(NSString *key))changeHandler
{
    @autoreleasepool {
        id<SPStorageProvider> threadSafeStorage = [bucket.storage threadSafeStorage];
		[threadSafeStorage beginSafeSection];
		
        NSMutableSet *addedKeys = [NSMutableSet setWithCapacity:5];
        NSMutableSet *changedKeys = [NSMutableSet setWithCapacity:5];
		
        // Batch fault all the objects into a dictionary for efficiency
        NSMutableArray *objectKeys = [NSMutableArray arrayWithCapacity:[versions count]];
        for (NSArray *versionData in versions) {
            [objectKeys addObject:[versionData objectAtIndex:0]];
        }
        NSDictionary *objects = [threadSafeStorage faultObjectsForKeys:objectKeys bucketName:bucket.name];
        
        // Process all version data
        for (NSArray *versionData in versions)
        {
            // Unmarshal the data
            NSString *key = [versionData objectAtIndex:0];
            NSString *responseString = [versionData objectAtIndex:1];
            NSString *version = [versionData objectAtIndex:2];
            NSMutableDictionary *data = [responseString sp_objectFromJSONString];
                              
            id<SPDiffable> object = [objects objectForKey:key];
            SPGhost *ghost = nil;
            
            if (!object) {
                // The object doesn't exist locally yet, so create it
                object = [threadSafeStorage insertNewObjectForBucketName:bucket.name simperiumKey:key];
                object.bucket = bucket; // set it manually since it won't be set automatically yet
                [object loadMemberData:data];    
                [addedKeys addObject:key];
                            
                NSMutableDictionary *newMemberData = [[object dictionary] mutableCopy];
                ghost = [[SPGhost alloc] initWithKey:[object simperiumKey] memberData:newMemberData];
                SPLogVerbose(@"Simperium added object from index (%@): %@", bucket.name, [object simperiumKey]);
            } else {
                // The object already exists locally; update it if necessary
                BOOL overwriteLocalData = NO;
                
                // The firstSync flag is set if there has not yet been a successful sync. In that case, additional checks
                // are performed to see if the local data should be preserved instead. This handles migrations from existing
                // sync systems (e.g. Simplenote GAE), and in particular, cases where there are local, unsynced changes that
                // should be preserved.
                if (firstSync) {
                    NSDictionary *diff = [bucket.differ diff:object withDictionary:data];
                    if ([diff count] > 0 && [object respondsToSelector:@selector(shouldOverwriteLocalChangesFromIndex)]) {
                        SPLogVerbose(@"Simperium object %@ has changes: %@", [object simperiumKey], diff);
                        if ([object performSelector:@selector(shouldOverwriteLocalChangesFromIndex)]) {
                            // The app has determined this object's local changes should be taken from index regardless of any local changes
                            SPLogVerbose(@"Simperium local object found (%@) with local changes, and OVERWRITING those changes", bucket.name);
                            overwriteLocalData = YES;
                        } else
                            // There's a local, unsynced change, which can only happen on first sync when migrating from an earlier version of an app.
                            // Allow the caller to deal with this case
                            changeHandler(key);
                    }
                    
                    // Set the ghost data (this expects all properties to be present in memberData)
                    ghost = [[SPGhost alloc] initWithKey:[object simperiumKey] memberData: data];                
                } else if (object.version != nil && ![version isEqualToString:object.version]) {
                    // Safe to do here since the local change has already been posted
                    overwriteLocalData = YES;
                }
                
                // Overwrite local changes if necessary
                if (overwriteLocalData) {
                    [object loadMemberData:data];
                    
                    // Be sure to load all members into ghost (since the version results might only contain a subset of members that were changed)
                    NSMutableDictionary *ghostMemberData = [[object dictionary] mutableCopy];
                     // might have already been allocated above
                    ghost = [[SPGhost alloc] initWithKey:[object simperiumKey] memberData: ghostMemberData];
                    [changedKeys addObject:key];
                    SPLogVerbose(@"Simperium loaded new data into object %@ (%@)", [object simperiumKey], bucket.name);
                }

            }
            
            // If there is a new/changed ghost, store it
            if (ghost) {
                SPLogVerbose(@"Simperium updating ghost data for object %@ (%@)", [object simperiumKey], bucket.name);
                ghost.version = version;
                object.ghost = ghost;
                object.simperiumKey = object.simperiumKey; // ugly hack to force entity to save since ghost isn't transient
            }
        }
        
        // Store after processing the batch for efficiency
        [threadSafeStorage save];
        [threadSafeStorage refaultObjects:[objects allValues]];
		[threadSafeStorage finishSafeSection];
		
        // Do all main thread work afterwards as well
        dispatch_async(dispatch_get_main_queue(), ^{
            // Manually resolve any pending references to added objects
            [bucket resolvePendingRelationshipsToKeys:addedKeys];
            [bucket.storage save];

            // Revisit the use of NSNotification if there is demand. Currently it's too slow when lots of data is being
            // indexed across buckets, so it's not done by default
            if (bucket.notifyWhileIndexing) {
                NSDictionary *userInfoAdded = @{
					@"bucketName"	: bucket.name,
					@"keys"			: addedKeys
				};

                [[NSNotificationCenter defaultCenter] postNotificationName:ProcessorDidAddObjectsNotification object:bucket userInfo:userInfoAdded];

                for (NSString *key in changedKeys) {
                    NSDictionary *userInfoChanged = @{
						@"bucketName"	: bucket.name,
						@"keys"			: [NSSet setWithObject:key]
					};
                    [[NSNotificationCenter defaultCenter] postNotificationName:ProcessorDidChangeObjectNotification object:bucket userInfo:userInfoChanged];
                }
            }
        });    
    }
}

- (NSArray*)exportIndexStatus:(SPBucket *)bucket {

	// This routine shall be used for debugging purposes!
	id<SPStorageProvider> storage	= bucket.storage;
	NSSet *localKeys				= [NSSet setWithArray:[storage objectKeysForBucketName:bucket.name]];
	NSArray *objects				= [storage objectsForKeys:localKeys bucketName:bucket.name];
	NSMutableArray* index			= [NSMutableArray array];
	
	for (id<SPDiffable>object in objects) {
		[index addObject:@{ [object.simperiumKey copy] : [object.ghost.version copy] }];
	}
	
	return index;
}

@end
