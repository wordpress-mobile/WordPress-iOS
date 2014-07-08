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

static SPLogLevels logLevel                         = SPLogLevelsInfo;
static NSInteger const SPIndexProcessorBatchSize    = 50;

typedef NS_ENUM(NSInteger, SPVersion) {
    SPVersionKey    = 0,
    SPVersionNumber = 1,
    SPVersionData   = 2
};


#pragma mark ====================================================================================
#pragma mark SPIndexProcessor
#pragma mark ====================================================================================

@implementation SPIndexProcessor

// Process an index of keys from the Simperium service for a particular bucket
- (void)processIndex:(NSArray *)indexArray bucket:(SPBucket *)bucket versionHandler:(SPVersionHandlerBlockType)versionHandler  {
    
    // indexArray could have thousands of items; break it up into batches to manage memory use
    NSMutableDictionary *indexDict  = [NSMutableDictionary dictionaryWithCapacity:[indexArray count]];
    NSInteger numBatches            = 1 + [indexArray count] / SPIndexProcessorBatchSize;
    NSMutableArray *batchLists      = [NSMutableArray arrayWithCapacity:numBatches];
    for (int i = 0; i<numBatches; i++) {
        [batchLists addObject: [NSMutableArray arrayWithCapacity:SPIndexProcessorBatchSize]];
    }
    
    // Build the batches
    int currentBatch = 0;
    NSMutableArray *currentBatchList = [batchLists objectAtIndex:currentBatch];
    for (NSDictionary *dict in indexArray) {
        NSString *key   = [dict objectForKey:@"id"];
        id version      = [dict objectForKey:@"v"];
        
        // Map it for convenience
        [indexDict setObject:version forKey:key];
        
        // Put it in a batch (advancing to next batch if necessary)
        [currentBatchList addObject:key];
        if ([currentBatchList count] == SPIndexProcessorBatchSize) {
            currentBatchList = [batchLists objectAtIndex:++currentBatch];
        }
    }
    
    // Take this opportunity to check for any objects that exist locally but not remotely, and remove them
    // (this can happen after reindexing if the client missed some remote deletion changes)
	NSSet *remoteKeySet = [NSSet setWithArray:[indexDict allKeys]];
	[self reconcileLocalAndRemoteIndex:remoteKeySet bucket:bucket];
    
    // Process each batch while being efficient with memory and faulting
    id<SPStorageProvider> storage = [bucket.storage threadSafeStorage];
	[storage beginSafeSection];
	
    for (NSMutableArray *batchList in batchLists) {
        @autoreleasepool {
        // Batch fault the entities for efficiency
            NSDictionary *objects = [storage faultObjectsForKeys:batchList bucketName:bucket.name];
            
            for (NSString *key in batchList) {
                id version = indexDict[key];
                
                // Store versions as strings, but if they come off the wire as numbers, then handle that too
                if ([version isKindOfClass:[NSNumber class]]) {
                    version = [NSString stringWithFormat:@"%ld", (long)[version integerValue]];
                }
                
                // Check to see if this entity already exists locally and is up to date
                id<SPDiffable> object = [objects objectForKey:key];
                if (object && object.ghost != nil && object.ghost.version != nil && [version isEqualToString:object.ghost.version]) {
                    continue;
                }
                
                // Allow caller to use the key and version
                versionHandler(key, version);
            }
            
            // Refault to free up the memory
            [storage refaultObjects:objects.allValues];
        }
    }
	
	[storage finishSafeSection];
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
- (void)processVersions:(NSArray *)versions bucket:(SPBucket *)bucket changeHandler:(SPChangeHandlerBlockType)changeHandler
{
    NSAssert([versions isKindOfClass:[NSArray class]],  @"Versions should be an array");
    NSAssert([bucket isKindOfClass:[SPBucket class]],   @"Invalid Bucket Pointer");
    NSAssert(changeHandler,                             @"Please, provide a change handler");
    
    @autoreleasepool {
        id<SPStorageProvider> storage = [bucket.storage threadSafeStorage];
		[storage beginSafeSection];
		
        NSMutableSet *addedKeys     = [NSMutableSet setWithCapacity:5];
        NSMutableSet *changedKeys   = [NSMutableSet setWithCapacity:5];
        NSMutableSet *rebasedKeys   = [NSMutableSet setWithCapacity:5];
		
        // Batch fault all the objects into a dictionary for efficiency
        NSMutableArray *objectKeys  = [NSMutableArray arrayWithCapacity:versions.count];
        for (NSArray *versionData in versions) {
            NSAssert([versionData isKindOfClass:[NSArray class]], @"Invalid Version");
            [objectKeys addObject:versionData[0]];
        }
        
        NSDictionary *objects = [storage faultObjectsForKeys:objectKeys bucketName:bucket.name];
        
        // Process all version data
        for (NSArray *versionData in versions)
        {            
            // Unmarshal the data
            NSString *key                   = versionData[SPVersionKey];
            NSString *version               = versionData[SPVersionNumber];
            NSDictionary *data              = versionData[SPVersionData];
            
            // Process the Object's Member Data
            id<SPDiffable> object           = objects[key];
            
            // The object doesn't exist locally yet, so create it
            if (!object) {
                object          = [storage insertNewObjectForBucketName:bucket.name simperiumKey:key];
                object.bucket   = bucket; // set it manually since it won't be set automatically yet
                [object loadMemberData:data];
                
                [addedKeys addObject:key];
                SPLogVerbose(@"Simperium added object from index (%@): %@", bucket.name, object.simperiumKey);
                
            // The object exists. Let's attempt to rebase local pending changes
            } else {

                // 1. Calculate Delta: LocalGhost > LocalMembers
                SPGhost *localGhost         = [object.ghost copy];
                NSDictionary *localDiff     = [bucket.differ diffFromDictionary:localGhost.memberData toObject:object];
                
                // 2. Load the full Remote Member Data
                [object loadMemberData:data];
                SPLogWarn(@"Simperium successfully reloaded local entity (%@): %@", bucket.name, key);
                
                // 3. Rebase + apply localDiff
                if (localDiff.count) {
                    
                    // 3.1. Calculate Delta: LocalGhost > RemoteMembers
                    NSDictionary *remoteDiff    = [bucket.differ diffFromDictionary:localGhost.memberData toObject:object];
                    
                    // 3.2. Transform localDiff: LocalGhost >> RemoteMembers >> LocalDiff (equivalent to git rebase)
                    NSError *error              = nil;
                    NSDictionary *rebaseDiff    = nil;
                    
                    if (remoteDiff.count) {
                        // Note: if remoteDiff is empty, there is just no need to rebase!.
                        rebaseDiff = [bucket.differ transform:object diff:localDiff oldDiff:remoteDiff oldGhost:localGhost error:&error];
                    } else {
                        rebaseDiff = localDiff;
                    }
                    
                    // 3.3. Attempt to apply the Local Transformed Diff
                    if (!error && rebaseDiff.count) {
                        [bucket.differ applyDiffFromDictionary:rebaseDiff toObject:object error:&error];
                    }
                    
                    // 3.4. Some debugging
                    if (error) {
                        SPLogWarn(@"Simperium error: could not apply local transformed diff for entity (%@): %@", bucket.name, key);
                    } else {
                        SPLogWarn(@"Simperium successfully updated local entity (%@): %@", bucket.name, key);
                    }
                    
                    // 3.5. Signal the changeHandler that the object has untracked changes. Do this after saving the storage!
                    [rebasedKeys addObject:key];
                }
                
                [changedKeys addObject:key];
            }
            
            // 4. Update the ghost with the remote member data + version
            SPGhost *ghost  = [[SPGhost alloc] initWithKey:object.simperiumKey memberData:[data mutableCopy]];
            ghost.version   = version;
            object.ghost    = ghost;
            
            SPLogVerbose(@"Simperium updating ghost data for object %@ (%@)", object.simperiumKey, bucket.name);
        }
        
        // Store after processing the batch for efficiency
        [storage save];
		[storage finishSafeSection];
		
        // Signal the changeHandler that the object has untracked changes
        for (NSString *key in rebasedKeys) {
            changeHandler(key);
        }
        
        // Do all main thread work afterwards as well
        dispatch_async(dispatch_get_main_queue(), ^{
            // Manually resolve any pending references to added objects
            [bucket resolvePendingRelationshipsToKeys:addedKeys];
            [bucket.storage save];

            // Revisit the use of NSNotification if there is demand. Currently it's too slow when lots of data is being
            // indexed across buckets, so it's not done by default
            if (!bucket.notifyWhileIndexing) {
                return;
            }
            
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
