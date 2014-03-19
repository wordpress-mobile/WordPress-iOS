//
//  SPChangeProcessor.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-15.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPChangeProcessor.h"
#import "SPPersistentMutableDictionary.h"
#import "SPPersistentMutableSet.h"
#import "SPManagedObject.h"
#import "NSString+Simperium.h"
#import "SPDiffer.h"
#import "SPStorage.h"
#import "SPMember.h"
#import "JSONKit+Simperium.h"
#import "SPGhost.h"
#import "SPLogger.h"
#import "SPBucket+Internals.h"
#import "SPDiffer.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static SPLogLevels logLevel			= SPLogLevelsInfo;

NSString * const CH_KEY				= @"id";
NSString * const CH_ADD				= @"+";
NSString * const CH_REMOVE			= @"-";
NSString * const CH_MODIFY			= @"M";
NSString * const CH_OPERATION		= @"o";
NSString * const CH_VALUE			= @"v";
NSString * const CH_START_VERSION   = @"sv";
NSString * const CH_END_VERSION     = @"ev";
NSString * const CH_CHANGE_VERSION	= @"cv";
NSString * const CH_LOCAL_ID		= @"ccid";
NSString * const CH_CLIENT_ID		= @"clientid";
NSString * const CH_ERROR           = @"error";
NSString * const CH_DATA            = @"d";
NSString * const CH_EMPTY			= @"EMPTY";

typedef NS_ENUM(NSUInteger, CH_ERRORS) {
	CH_ERRORS_EXPECTATION_FAILED	= 417,		// (e.g. foreign key doesn't exist just yet)
    CH_ERRORS_INVALID_DIFF			= 440,
	CH_ERRORS_THRESHOLD				= 503
};

static int const SPChangeProcessorMaxPendingChanges	= 200;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPChangeProcessor()
@property (nonatomic, strong, readwrite) NSString						*label;
@property (nonatomic, strong, readwrite) SPPersistentMutableDictionary	*changesPending;
@property (nonatomic, strong, readwrite) SPPersistentMutableSet			*keysForObjectsWithMoreChanges;
@property (nonatomic, strong, readwrite) SPPersistentMutableSet			*keysForObjectsWithPendingRetry;
@end


#pragma mark ====================================================================================
#pragma mark SPChangeProcessor
#pragma mark ====================================================================================

@implementation SPChangeProcessor

- (id)initWithLabel:(NSString *)label {
    if (self = [super init]) {
        self.label			= label;
		self.changesPending = [SPPersistentMutableDictionary loadDictionaryWithLabel:label];
		
		NSString *moreKey = [NSString stringWithFormat:@"keysForObjectsWithMoreChanges-%@", label];
        self.keysForObjectsWithMoreChanges = [SPPersistentMutableSet loadSetWithLabel:moreKey];
		
		NSString *retryKey = [NSString stringWithFormat:@"keysForObjectsWithPendingRetry-%@", label];
        self.keysForObjectsWithPendingRetry = [SPPersistentMutableSet loadSetWithLabel:retryKey];
		
		[self migratePendingChangesIfNeeded];
    }
    
    return self;
}

- (void)reset {
    [self.changesPending removeAllObjects];
    [self.keysForObjectsWithMoreChanges removeAllObjects];
	[self.keysForObjectsWithPendingRetry removeAllObjects];
	
	[self.changesPending save];
    [self.keysForObjectsWithMoreChanges save];
	[self.keysForObjectsWithPendingRetry save];
}


#pragma mark ====================================================================================
#pragma mark Remote changes
#pragma mark ====================================================================================

- (void)processRemoteResponseForChanges:(NSArray *)changes bucket:(SPBucket *)bucket repostNeeded:(BOOL *)repostNeeded {

	NSAssert(repostNeeded != nil, @"RepostNeeded is not optional");
	
    for (NSDictionary *change in changes) {
        if (change[CH_ERROR] == nil) {
			continue;
		}

		NSString *key	= [self keyWithoutNamespaces:change bucket:bucket];
		long errorCode	= [change[CH_ERROR] integerValue];
		
		SPLogError(@"Simperium POST returned error %ld for change %@", errorCode, change);
		
		if (errorCode == CH_ERRORS_THRESHOLD) {

			// Re-enqueue failed changes
			[self.keysForObjectsWithPendingRetry addObject:key];
			[self.keysForObjectsWithPendingRetry save];
			
		} else if (errorCode == CH_ERRORS_EXPECTATION_FAILED || errorCode == CH_ERRORS_INVALID_DIFF) {
			// Resubmit with all data
			// Create a new context (to be thread-safe) and fetch the entity from it
			id<SPStorageProvider>threadSafeStorage = [bucket.storage threadSafeStorage];
			[threadSafeStorage beginSafeSection];

			id<SPDiffable>object = [threadSafeStorage objectForKey:key bucketName :bucket.name];
			
			if (!object) {
				[self.changesPending removeObjectForKey:key];
				[threadSafeStorage finishSafeSection];
				continue;
			}
			NSMutableDictionary *newChange = [[self.changesPending objectForKey:key] mutableCopy];

			[object simperiumKey]; // fire fault
			[newChange setObject:[object dictionary] forKey:CH_DATA];
			[self.changesPending setObject:newChange forKey:key];
			*repostNeeded = YES;
			
			[threadSafeStorage finishSafeSection];
		} else {
			// Catch all, don't resubmit
			[self.changesPending removeObjectForKey:key];
		}
    }
	
	[self.changesPending save];
}

- (BOOL)processRemoteDeleteWithKey:(NSString*)simperiumKey bucket:(SPBucket *)bucket acknowledged:(BOOL)acknowledged {
	
	// REMOVE operation
	// If this wasn't just an ack, perform the deletion
	if (!acknowledged) {
		SPLogVerbose(@"Simperium non-local REMOVE ENTITY received");
		
		id<SPStorageProvider> threadSafeStorage = [bucket.storage threadSafeStorage];
		[threadSafeStorage beginCriticalSection];
		
		id<SPDiffable> object = [threadSafeStorage objectForKey:simperiumKey bucketName:bucket.name];
		
		if (object) {
			[threadSafeStorage deleteObject:object];
			[threadSafeStorage save];
		}

		[threadSafeStorage finishCriticalSection];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			NSDictionary *userInfo = @{
										@"bucketName"	: bucket.name,
										@"keys"			: [NSSet setWithObject:simperiumKey]
									 };
			[[NSNotificationCenter defaultCenter] postNotificationName:ProcessorDidDeleteObjectKeysNotification object:bucket userInfo:userInfo];
		});

	} else {
		dispatch_async(dispatch_get_main_queue(), ^{
			// Not really useful except for testing
			NSDictionary *userInfo = @{  @"bucketName" : bucket.name };
			[[NSNotificationCenter defaultCenter] postNotificationName:ProcessorDidAcknowledgeDeleteNotification object:bucket userInfo:userInfo];
		});
	}
	
    return YES;
}

- (BOOL)processRemoteModifyWithKey:(NSString *)simperiumKey bucket:(SPBucket *)bucket change:(NSDictionary *)change
					  acknowledged:(BOOL)acknowledged clientMatches:(BOOL)clientMatches
{
    id<SPStorageProvider>threadSafeStorage = [bucket.storage threadSafeStorage];
	[threadSafeStorage beginSafeSection];
	
    id<SPDiffable> object = [threadSafeStorage objectForKey:simperiumKey bucketName:bucket.name];
	
    BOOL newlyAdded = NO;
    NSString *key = [self keyWithoutNamespaces:change bucket:bucket];
    
    // MODIFY operation
    if (!object) {
		// If the change was sent by this very same client, and the object isn't available, don't add it.
		// It Must have been locally deleted before the confirmation got through!
		if (clientMatches) {
			[threadSafeStorage finishSafeSection];
			return NO;
		}
		
        // It doesn't exist yet, so ADD it
        newlyAdded = YES;
		
        // Create the new object
        object = [threadSafeStorage insertNewObjectForBucketName:bucket.name simperiumKey:key];
        SPLogVerbose(@"Simperium managing newly added entity %@", [object simperiumKey]);
        
        // Remember this object's ghost for future diffing			
        // Send nil member data because it'll get loaded below
        SPGhost *ghost = [[SPGhost alloc] initWithKey:[object simperiumKey] memberData:nil];
        ghost.version = @"0";
        object.ghost = ghost;
        
        // If this wasn't just an ack, send a notification and load the data
        SPLogVerbose(@"Simperium non-local ADD ENTITY received");
    }
    
    // Another hack since 'ghost' isn't transient: check for fault and forcefire if necessary
    [object willBeRead];
    
    // It already exists, now MODIFY it
    if (!object.ghost) {
        SPLogWarn(@"Simperium warning: received change for unknown entity (%@): %@", bucket.name, key);
		[threadSafeStorage finishSafeSection];
        return NO;
    }
    
    // Make sure the expected last change matches the actual last change
    NSString *oldVersion	= [object.ghost version];
    id startVersion			= change[CH_START_VERSION];
    id endVersion			= change[CH_END_VERSION];
    
    // Store versions as strings, but if they come off the wire as numbers, then handle that too
    if ([startVersion isKindOfClass:[NSNumber class]]) {
        startVersion = [NSString stringWithFormat:@"%ld", (long)[startVersion integerValue]];
	}
	
    if ([endVersion isKindOfClass:[NSNumber class]]) {
        endVersion = [NSString stringWithFormat:@"%ld", (long)[endVersion integerValue]];
    }
	
	// If the local version matches the remote endVersion, don't process this change: it's a dupe message
	if ([object.ghost.version isEqual:endVersion]) {
		[threadSafeStorage finishSafeSection];
		return NO;
	}
	
    SPLogVerbose(@"Simperium received version = %@, previous version = %@", startVersion, oldVersion);
    // If the versions are equal or there's no start version (new object), process the change
    if (startVersion == nil || [oldVersion isEqualToString:startVersion]) {
        // Remember the old ghost
        SPGhost *oldGhost = [object.ghost copy];
        NSDictionary *diff = [change objectForKey:CH_VALUE];
        
        // Apply the diff to the ghost and store the new data in the object's ghost
        [bucket.differ applyGhostDiff: diff to:object];
        object.ghost.version = endVersion;
        
        // Slight hack to ensure Core Data realizes the object has changed and needs a save
        NSString *ghostDataCopy = [[[object.ghost dictionary] sp_JSONString] copy];
        object.ghostData = ghostDataCopy;
        
        SPLogVerbose(@"Simperium MODIFIED ghost version %@ (%@-%@)", endVersion, bucket.name, self.label);
        
        // If it wasn't an ack, then local data needs to be updated and the app needs to be notified
        if (!acknowledged && !newlyAdded) {
            SPLogVerbose(@"Simperium non-local MODIFY ENTITY received");
            NSDictionary *oldDiff = [bucket.differ diff:object withDictionary:[oldGhost memberData]];
            if ([oldDiff count] > 0) {
                // The local client version changed in the meantime, so transform the diff before applying it
                SPLogVerbose(@"Simperium applying transform to diff: %@", diff);			
                diff = [bucket.differ transform:object diff:oldDiff oldDiff: diff oldGhost: oldGhost];
                
                // Load from the ghost data so the subsequent diff is applied to the correct data
                // Do an extra check in case there was a problem with the transform/diff, e.g. if a client's own change was misinterpreted
                // as another client's change, in other words not properly acknowledged.
                if ([diff count] > 0) {
                    [object loadMemberData: [object.ghost memberData]];
                } else {
                    SPLogVerbose(@"Simperium transform resulted in empty diff (invalid ack?)");
				}
            }
        }
        
        // Apply the diff to the object itself
        if (!acknowledged && [diff count] > 0) {
            SPLogVerbose(@"Simperium applying diff: %@", diff);
            [bucket.differ applyDiff: diff to:object];
        }
        [threadSafeStorage save];
		
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      bucket.name, @"bucketName",
                                      [NSSet setWithObject:key], @"keys", nil];
            NSString *notificationName;
            if (newlyAdded) {
                notificationName = ProcessorDidAddObjectsNotification;
            } else if (acknowledged) {
                notificationName = ProcessorDidAcknowledgeObjectsNotification;
            } else {
                notificationName = ProcessorDidChangeObjectNotification;                
                [userInfo setObject:[diff allKeys] forKey:@"changedMembers"];
            }
			
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:bucket userInfo:userInfo];
        });
        
    } else {
        SPLogWarn(@"Simperium warning: couldn't apply change due to version mismatch (duplicate? start %@, old %@): change %@", startVersion, oldVersion, change);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ProcessorRequestsReindexing object:bucket];
        });
    }
	
	[threadSafeStorage finishSafeSection];
	
    return YES;
}

- (BOOL)processRemoteChange:(NSDictionary *)change bucket:(SPBucket *)bucket clientID:(NSString *)clientID {
	
	// Check for an error
    NSString *key	= [self keyWithoutNamespaces:change bucket:bucket];
	NSString *error = change[CH_ERROR];
    if (error) {
		// Note: Error handling is performed by 'processRemoteResponseForChanges:' method. Just don't process the change
        return NO;
    }
	
    // Create a new context (to be thread-safe) and fetch the entity from it
    id<SPStorageProvider>threadSafeStorage = [bucket.storage threadSafeStorage];
	[threadSafeStorage beginSafeSection];
	
    NSString *operation			= change[CH_OPERATION];
    NSString *changeVersion		= change[CH_CHANGE_VERSION];
    NSString *changeClientID	= change[CH_CLIENT_ID];
    id<SPDiffable> object		= [threadSafeStorage objectForKey:key bucketName:bucket.name];
    
    SPLogVerbose(@"Simperium client %@ received change (%@) %@: %@", clientID, bucket.name, changeClientID, change);
	
	// Process
    BOOL clientMatches			= [changeClientID compare:clientID] == NSOrderedSame;
    BOOL remove					= operation && [operation compare: CH_REMOVE] == NSOrderedSame;
    BOOL acknowledged			= [self awaitingAcknowledgementForKey:key] && clientMatches;
    
    // If the entity already exists locally, or it's being removed, then check for an ack
    if (remove || (object && acknowledged && clientMatches)) {
        // TODO: If this isn't a deletion change, but there's a deletion change pending, then ignore this change
        // Change was awaiting acknowledgement; safe now to remove from changesPending
        if (acknowledged) {
            SPLogVerbose(@"Simperium acknowledged change for %@, cv=%@", changeClientID, changeVersion);
		}
        [self.changesPending removeObjectForKey:key];
    }

    SPLogVerbose(@"Simperium performing change operation: %@", operation);
	[threadSafeStorage finishSafeSection];
		
    if (remove) {
        if (object || acknowledged) {
            return [self processRemoteDeleteWithKey:key bucket:bucket acknowledged:acknowledged];
		}
    } else if (operation && [operation compare: CH_MODIFY] == NSOrderedSame) {
        return [self processRemoteModifyWithKey:key bucket:bucket change:change acknowledged:acknowledged clientMatches:clientMatches];
    }
	
	// invalid
	SPLogError(@"Simperium error (%@), received an invalid change for (%@): %@", bucket.name, key, change);
    return NO;
}

- (void)processRemoteChanges:(NSArray *)changes bucket:(SPBucket *)bucket clientID:(NSString *)clientID {
    NSMutableSet *changedKeys = [NSMutableSet setWithCapacity:[changes count]];
    
    // Construct a list of keys for a willChange notification (and ignore acks)
    for (NSDictionary *change in changes) {
        NSString *key = [self keyWithoutNamespaces:change bucket:bucket];
        if (![self awaitingAcknowledgementForKey:key]) {
            [changedKeys addObject:key];
		}
    }

	dispatch_async(dispatch_get_main_queue(), ^{
			
		if (changedKeys.count > 0) {
			NSDictionary *userInfo = @{
										@"bucketName"	: bucket.name,
										@"keys"			: changedKeys
									 };
			
			[[NSNotificationCenter defaultCenter] postNotificationName:ProcessorWillChangeObjectsNotification object:bucket userInfo:userInfo];
		}
		
        // The above notification needs to give the main thread a chance to react before we continue
        dispatch_async(bucket.processorQueue, ^{
			@autoreleasepool {				
				for (NSDictionary *change in changes) {
					// Process the change (this is necessary even if it's an ack, so the ghost data gets set accordingly)
					if (![self processRemoteChange:change bucket:bucket clientID:clientID]) {
						continue;
					}
					
					// Remember the last version
					// This persists...do it inside the loop in case something happens to abort the loop
					NSString *changeVersion = change[CH_CHANGE_VERSION];
					
					dispatch_async(dispatch_get_main_queue(), ^{
						[bucket setLastChangeSignature: changeVersion];
					});        
				}
			}
			
			[self.changesPending save];
			
			if (self.changesPending.count == 0) {
				[bucket bucketDidSync];
			}
        });
    });
}


#pragma mark ====================================================================================
#pragma mark Local changes
#pragma mark ====================================================================================

- (NSDictionary *)processLocalDeletionWithKey:(NSString *)key {
	NSDictionary *change = [self createChangeForKey:key operation:CH_REMOVE version:nil data:nil];

	if (change) {
		[self.changesPending setObject:change forKey:key];
		[self.changesPending save];
	}
	
	return change;
}

- (void)markObjectWithPendingChanges:(NSString *)key bucket:(SPBucket *)bucket {
	SPLogVerbose(@"Simperium marking object for sending more changes when ready (%@): %@", bucket.name, key);
	[self.keysForObjectsWithMoreChanges addObject:key];
	[self.keysForObjectsWithMoreChanges save];
}

- (NSDictionary *)processLocalObjectWithKey:(NSString *)key bucket:(SPBucket *)bucket {
	
    // Create a new context (to be thread-safe) and fetch the entity from it
    id<SPStorageProvider> storage = [bucket.storage threadSafeStorage];
    
	[storage beginSafeSection];
    id<SPDiffable> object = [storage objectForKey:key bucketName:bucket.name];
	
    // If the object no longer exists, it was likely previously deleted, in which case this change is no longer relevant
    if (!object) {
        SPLogWarn(@"Simperium warning: couldn't processLocalObjectWithKey %@ because the object no longer exists", key);
        [self.changesPending removeObjectForKey:key];
		[self.changesPending save];
        [self.keysForObjectsWithMoreChanges removeObject:key];
        [self.keysForObjectsWithMoreChanges save];
		[storage finishSafeSection];
        return nil;
    }

    // If there are already changes pending for this entity, mark this entity and come back to it later to get the changes
    if ([self.changesPending containsObjectForKey:key]) {
		[self markObjectWithPendingChanges:key bucket:bucket];
		[storage finishSafeSection];
        return nil;
    }
	
    NSDictionary *change = nil;
	
    SPLogVerbose(@"Simperium processing local object changes (%@): %@", bucket.name, object.simperiumKey); 
    
    if (object.ghost != nil && [object.ghost memberData] != nil) {
        // This object has already been synced in the past and has a server ghost, so we're modifying the object
        
        // Get a diff of the object (in dictionary form)
		NSDictionary *newData = [bucket.differ diff:object withDictionary: [object.ghost memberData]];
        SPLogVerbose(@"Simperium entity diff found %lu changed members", (unsigned long)newData.count);
		
        if (newData.count > 0) {
            change = [self createChangeForKey: object.simperiumKey operation: CH_MODIFY version:object.ghost.version data: newData];
        } else {
            // No difference, don't do anything else
            SPLogVerbose(@"Simperium warning: no difference in call to sendChanges (%@): %@", bucket.name, object.simperiumKey);
        }
        
    } else  {
        SPLogVerbose(@"Simperium local ADD detected, creating diff...");
        
		NSDictionary *newData = [bucket.differ diffForAddition:object];
        change = [self createChangeForKey: object.simperiumKey operation:CH_MODIFY version: object.ghost.version data: newData];
    }
    
	[storage finishSafeSection];
	
	// Persist the change
	if (change) {
		[self.changesPending setObject:change forKey:key];
		[self.changesPending save];
	}
	
	// And return!
    return change;
}

- (NSDictionary *)processLocalBucketDeletion:(SPBucket *)bucket {
	return [self createChangeForKey:bucket.name operation:CH_EMPTY version:nil data:nil];
}

- (void)enumeratePendingChangesForBucket:(SPBucket *)bucket block:(SPChangeEnumerationBlockType)block {
	
	NSArray *pendingKeys = self.changesPending.allKeys;
    if (pendingKeys.count == 0) {
		return;
	}
	
	SPLogVerbose(@"Simperium found %lu objects with pending changes to send (%@)", (unsigned long)pendingKeys.count, bucket.name);
	BOOL stop = NO;
	
	for (NSString *key in pendingKeys) {
		NSDictionary* change = [self.changesPending objectForKey:key];
		if (change) {
			block(change, &stop);
		}
		
		if (stop) {
			break;
		}
	}
}

- (void)enumerateQueuedChangesForBucket:(SPBucket *)bucket block:(SPChangeEnumerationBlockType)block {
	
	NSArray *pendingKeys = self.keysForObjectsWithMoreChanges.allObjects;
    if (pendingKeys.count == 0) {
		return;
	}
	
	SPLogVerbose(@"Simperium found %lu objects with more changes to send (%@)", (unsigned long)pendingKeys.count, bucket.name);
	
	NSMutableSet *processedKeys	= [NSMutableSet setWithCapacity:pendingKeys.count];
	BOOL stop = NO;
	
	for (NSString *key in pendingKeys) {
		// If there are already changes pending, don't add any more
		// Importantly, this prevents a potential mutation of keysForObjectsWithMoreChanges in processLocalObjectWithKey:later:
		if ([self.changesPending containsObjectForKey:key]) {
			continue;
		}
		
		// Create changes for any objects that has more changes
		NSDictionary *change = [self processLocalObjectWithKey:key bucket:bucket];
		if (change) {
			[self.changesPending setObject:change forKey:key];
			block(change, &stop);
		}

		[processedKeys addObject:key];
		
		if (stop) {
			break;
		}
	}
	
	// Clear any keys that were processed into pending changes
	[self.keysForObjectsWithMoreChanges minusSet:processedKeys];
    [self.keysForObjectsWithMoreChanges save];
	
	// Persist pending changes
	[self.changesPending save];
}

- (void)enumerateRetryChangesForBucket:(SPBucket *)bucket block:(SPChangeEnumerationBlockType)block {
	
	NSArray *retryKeys = self.keysForObjectsWithPendingRetry.allObjects;
	if (retryKeys.count == 0) {
		return;
	}
	
	SPLogVerbose(@"Simperium found %lu objects in the retry queue (%@)", (unsigned long)retryKeys.count, bucket.name);
	NSMutableSet *processedKeys = [NSMutableSet set];
	BOOL stop = NO;
	
	for (NSString *key in retryKeys) {
		NSDictionary* change = [self.changesPending objectForKey:key];
		if (change) {
			block(change, &stop);
		}
		
		[processedKeys addObject:key];
		
		if (stop) {
			break;
		}
	}
	
	[self.keysForObjectsWithPendingRetry minusSet:processedKeys];
	[self.keysForObjectsWithPendingRetry save];
}

- (BOOL)hasReachedMaxPendings {
	return (self.changesPending.count >= SPChangeProcessorMaxPendingChanges);
}


#pragma mark ====================================================================================
#pragma mark Remote Logging
#pragma mark ====================================================================================

- (NSArray*)exportPendingChanges {
	
	// This routine shall be used for debugging purposes!
	NSMutableArray* pendings = [NSMutableArray array];
	for (NSDictionary* change in self.changesPending.allValues) {
				
		NSMutableDictionary* export = [NSMutableDictionary dictionary];
		
		[export setObject:[change[CH_KEY] copy] forKey:CH_KEY];				// Entity Id
		[export setObject:[change[CH_LOCAL_ID] copy] forKey:CH_LOCAL_ID];	// Change Id: ccid
		
		// Start Version is not available for newly inserted objects
		NSString* startVersion = change[CH_START_VERSION];
		if (startVersion) {
			[export setObject:[startVersion copy] forKey:CH_START_VERSION];
		}
		
		[pendings addObject:export];
	}
	
	return pendings;
}


#pragma mark ====================================================================================
#pragma mark Properties
#pragma mark ====================================================================================

- (int)numChangesPending {
    return (int)self.changesPending.count;
}

- (int)numKeysForObjectsWithMoreChanges {
    return (int)self.keysForObjectsWithMoreChanges.count;
}


#pragma mark ====================================================================================
#pragma mark Private Helpers
#pragma mark ====================================================================================

- (NSString *)keyWithoutNamespaces:(NSDictionary *)change bucket:(SPBucket *)bucket {
	
	NSString *changeKey = change[CH_KEY];
	if (!bucket.exposeNamespace) {
		return changeKey;
	}
	
	// Proceed removing our local namespace
	NSString *namespace = [bucket.localNamespace stringByAppendingString:@"/"];
	return [changeKey stringByReplacingOccurrencesOfString:namespace withString:@""];
}

- (NSMutableDictionary *)createChangeForKey:(NSString *)key operation:(NSString *)operation version:(NSString *)version data:(NSDictionary *)data {
	// The change applies to this particular entity instance, so use its unique key as an identifier
	NSMutableDictionary *change = [NSMutableDictionary dictionaryWithObject:key forKey:CH_KEY];
	
	// Every change must be marked with a unique ID
	NSString *uuid = [NSString sp_makeUUID];
	[change setObject:uuid forKey: CH_LOCAL_ID];
	
	// Set the change's operation
	[change setObject:operation forKey:CH_OPERATION];
    
	// Set the data as the value for the operation (e.g. a diff dictionary for modify operations)
    if (data) {
        [change setObject:data forKey:CH_VALUE];
	}
	
	// If it's a modify operation, also include the object's version as the last known version
	if (operation == CH_MODIFY && version != nil && [version intValue] != 0) {
        [change setObject: version forKey: CH_START_VERSION];
	}
	
	return change;
}

- (BOOL)awaitingAcknowledgementForKey:(NSString *)key {
	return [self.changesPending containsObjectForKey:key];
}

// Note: We've moved changesPending collection to SPDictionaryStorage class, which will help to lower memory requirements.
// This method will migrate any pending changes, from UserDefaults over to SPDictionaryStorage
//
- (void)migratePendingChangesIfNeeded {
    NSString *pendingKey = [NSString stringWithFormat:@"changesPending-%@", self.label];
	NSString *pendingJSON = [[NSUserDefaults standardUserDefaults] objectForKey:pendingKey];
	
	// No need to go further
	if (pendingJSON == nil) {
		return;
	}
	
	// Proceed migrating!
    SPLogInfo(@"Migrating changesPending collection to SPDictionaryStorage");
    
    NSDictionary *pendingDict = [pendingJSON sp_objectFromJSONString];
	
	for (NSString *key in pendingDict.allKeys) {
		id change = pendingDict[key];
		if (change) {
			[self.changesPending setObject:change forKey:key];
		}
	}
	
	[self.changesPending save];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:pendingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
