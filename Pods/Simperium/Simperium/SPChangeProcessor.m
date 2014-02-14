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
#import "SPBinaryManager.h"
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

typedef NS_ENUM(NSUInteger, CH_ERRORS) {
	CH_ERRORS_EXPECTATION_FAILED	= 417,		// (e.g. foreign key doesn't exist just yet)
    CH_ERRORS_INVALID_DIFF			= 440
};


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPChangeProcessor()
@property (nonatomic, strong, readwrite) NSString						*instanceLabel;
@property (nonatomic, strong, readwrite) SPPersistentMutableDictionary	*changesPending;
@property (nonatomic, strong, readwrite) SPPersistentMutableSet			*keysForObjectsWithMoreChanges;
@end


#pragma mark ====================================================================================
#pragma mark SPChangeProcessor
#pragma mark ====================================================================================

@implementation SPChangeProcessor

- (id)initWithLabel:(NSString *)label {
    if (self = [super init]) {
        self.instanceLabel = label;
		self.changesPending = [SPPersistentMutableDictionary loadDictionaryWithLabel:label];
		
		NSString *moreKey = [NSString stringWithFormat:@"keysForObjectsWithMoreChanges-%@", self.instanceLabel];
        self.keysForObjectsWithMoreChanges = [SPPersistentMutableSet loadSetWithLabel:moreKey];
		
		[self migratePendingChangesIfNeeded];
    }
    
    return self;
}


- (BOOL)awaitingAcknowledgementForKey:(NSString *)key {
	return [self.changesPending containsObjectForKey:key];
}

// Note: We've moved changesPending collection to SPDictionaryStorage class, which will help to lower memory requirements.
// This method will migrate any pending changes, from UserDefaults over to SPDictionaryStorage
- (void)migratePendingChangesIfNeeded {
    NSString *pendingKey = [NSString stringWithFormat:@"changesPending-%@", self.instanceLabel];
	NSString *pendingJSON = [[NSUserDefaults standardUserDefaults] objectForKey:pendingKey];
	
	// No need to go further
	if(pendingJSON == nil) {
		return;
	}
	
	// Proceed migrating!
    SPLogInfo(@"Migrating changesPending collection to SPDictionaryStorage");
    
    NSDictionary *pendingDict = [pendingJSON sp_objectFromJSONString];

	for(NSString *key in pendingDict.allKeys) {
		id change = pendingDict[key];
		if(change) {
			[self.changesPending setObject:change forKey:key];
		}
	}
	
	[self.changesPending save];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:pendingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)reset {
    [self.changesPending removeAllObjects];
	[self.changesPending save];
    [self.keysForObjectsWithMoreChanges removeAllObjects];
    [self.keysForObjectsWithMoreChanges save];
}


#pragma mark Remote changes

- (BOOL)change:(NSDictionary *)change equals:(NSDictionary *)anotherChange {
	return [change[CH_KEY] compare:anotherChange[CH_KEY]] == NSOrderedSame &&
			[change[CH_LOCAL_ID] compare:anotherChange[CH_LOCAL_ID]] == NSOrderedSame;
}

- (BOOL)processRemoteResponseForChanges:(NSArray *)changes bucket:(SPBucket *)bucket {
    BOOL repostNeeded = NO;
    for (NSDictionary *change in changes) {
        if (change[CH_ERROR] == nil) {
			continue;
		}

		NSString *key	= change[CH_KEY];
		long errorCode	= [change[CH_ERROR] integerValue];
		
		SPLogError(@"Simperium POST returned error %ld for change %@", errorCode, change);
		
		if (errorCode == CH_ERRORS_EXPECTATION_FAILED || errorCode == CH_ERRORS_INVALID_DIFF) {
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
			repostNeeded = YES;
			
			[threadSafeStorage finishSafeSection];
		} else {
			// Catch all, don't resubmit
			[self.changesPending removeObjectForKey:key];
		}
    }
	
	[self.changesPending save];
    
    return repostNeeded;
}

- (BOOL)processRemoteDeleteWithKey:(NSString*)simperiumKey bucket:(SPBucket *)bucket acknowledged:(BOOL)acknowledged {
	
	// REMOVE operation
	// If this wasn't just an ack, perform the deletion
	if (!acknowledged) {
		SPLogVerbose(@"Simperium non-local REMOVE ENTITY received");
		
		id<SPStorageProvider> threadSafeStorage = [bucket.storage threadSafeStorage];
		[threadSafeStorage beginCriticalSection];
		
		id<SPDiffable> object = [threadSafeStorage objectForKey:simperiumKey bucketName:bucket.name];
		
		if(object) {
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
    NSString *key = change[CH_KEY];
    
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
        
        SPLogVerbose(@"Simperium MODIFIED ghost version %@ (%@-%@)", endVersion, bucket.name, self.instanceLabel);
        
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
    NSString *key	= change[CH_KEY];
	NSString *error = change[CH_ERROR];
    if (error) {
        SPLogVerbose(@"Simperium error received (%@) for %@, should reload the object here to be safe", bucket.name, key);
        [self.changesPending removeObjectForKey:key];
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
        NSString *key = change[CH_KEY];
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
			
			[self.changesPending save];
			
			if(self.changesPending.count == 0) {
				[bucket bucketDidSync];
			}
        });
    });
}


#pragma mark Local changes

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

- (void)processLocalChange:(NSDictionary *)change key:(NSString *)key {
    [self.changesPending setObject:change forKey:key];
	[self.changesPending save];
}

- (NSDictionary *)processLocalDeletionWithKey:(NSString *)key {
	return [self createChangeForKey:key operation:CH_REMOVE version:nil data:nil];
}

- (NSDictionary *)processLocalObjectWithKey:(NSString *)key bucket:(SPBucket *)bucket later:(BOOL)later {
    // Create a new context (to be thread-safe) and fetch the entity from it
    id<SPStorageProvider> storage = [bucket.storage threadSafeStorage];
	[storage beginSafeSection];
	
    id<SPDiffable> object = [storage objectForKey:key bucketName:bucket.name];
    
    // If the object no longer exists, it was likely previously deleted, in which case this change is no longer
    // relevant
    if (!object) {
        //SPLogWarn(@"Simperium warning: couldn't processLocalObjectWithKey %@ because the object no longer exists", key);
        [self.changesPending removeObjectForKey:key];
		[self.changesPending save];
        [self.keysForObjectsWithMoreChanges removeObject:key];
        [self.keysForObjectsWithMoreChanges save];
		[storage finishSafeSection];
        return nil;
    }
    
    // If there are already changes pending for this entity, mark this entity and come back to it later to get the changes
    if (([self.changesPending objectForKey:object.simperiumKey] != nil) || later) {
        SPLogVerbose(@"Simperium marking object for sending more changes when ready (%@): %@", bucket.name, object.simperiumKey);
        [self.keysForObjectsWithMoreChanges addObject:[object simperiumKey]];
        [self.keysForObjectsWithMoreChanges save];
		[storage finishSafeSection];
        return nil;
    }
    
    NSDictionary *change = nil;
    SPLogVerbose(@"Simperium processing local object changes (%@): %@", bucket.name, object.simperiumKey); 
    
    if (object.ghost != nil && [object.ghost memberData] != nil) {
        // This object has already been synced in the past and has a server ghost, so we're
        // modifying the object
        
        // Get a diff of the object (in dictionary form)
		NSDictionary *newData = [bucket.differ diff:object withDictionary: [object.ghost memberData]];
        SPLogVerbose(@"Simperium entity diff found %lu changed members", (unsigned long)[newData count]);
        if ([newData count] > 0) {
            change = [self createChangeForKey: object.simperiumKey operation: CH_MODIFY version:object.ghost.version data: newData];
        } else {
            // No difference, don't do anything else
            SPLogVerbose(@"Simperium warning: no difference in call to sendChanges (%@): %@", bucket.name, object.simperiumKey);
        }
        
    } else /*if (!entity.deleted)*/ {
        SPLogVerbose(@"Simperium local ADD detected, creating diff...");
        
		NSDictionary *newData = [bucket.differ diffForAddition:object];
        change = [self createChangeForKey: object.simperiumKey operation:CH_MODIFY version: object.ghost.version data: newData];
    }
    
	[storage finishSafeSection];
	
    return change;
}

- (void)enumeratePendingChanges:(SPBucket *)bucket onlyQueuedChanges:(BOOL)onlyQueuedChanges block:(void (^)(NSDictionary *change))block {

    if (self.keysForObjectsWithMoreChanges.count == 0 && (onlyQueuedChanges || self.changesPending.count == 0)) {
		return;
	}
	
	SPLogVerbose(@"Simperium found %lu objects with more changes to send (%@)", (unsigned long)self.keysForObjectsWithMoreChanges.count, bucket.name);
	
    NSMutableSet *queuedKeys = [NSMutableSet setWithCapacity:self.keysForObjectsWithMoreChanges.count];
	NSMutableSet *pendingKeys = [NSMutableSet setWithArray:self.changesPending.allKeys];
	
	// Create a list of the keys to be processed
	for (NSString *key in self.keysForObjectsWithMoreChanges) {
		// If there are already changes pending, don't add any more
		// Importantly, this prevents a potential mutation of keysForObjectsWithMoreChanges in processLocalObjectWithKey:later:
		if ([pendingKeys containsObject:key] == NO) {
			[queuedKeys addObject:key];
		}
	}
	
	// Create changes for any objects that have more changes
	for(NSString* key in queuedKeys) {
		NSDictionary *change = [self processLocalObjectWithKey:key bucket:bucket later:NO];
		
		if (change) {
			[self.changesPending setObject:change forKey:key];
			[pendingKeys addObject:key];
		} else {
			[self.keysForObjectsWithMoreChanges removeObject:key];
		}
	}
	
	// Enumerate:
	//	pendingKeys: Queued + previously pending
	//	queuedKeys: Only queued objects
	NSSet *changesPendingKeys = (onlyQueuedChanges ? queuedKeys : pendingKeys);
		
	for(NSString *key in changesPendingKeys) {
		NSDictionary* change = [self.changesPending objectForKey:key];
		if(change) {
			block(change);
		}
	}

	// Clear any keys that were processed into pending changes & Persist
	[self.changesPending save];
	[self.keysForObjectsWithMoreChanges minusSet:queuedKeys];
    [self.keysForObjectsWithMoreChanges save];
}

- (NSArray *)processKeysForObjectsWithMoreChanges:(SPBucket *)bucket {
    // Check if there are more changes that need to be sent
    NSMutableArray *newChangesPending = [NSMutableArray arrayWithCapacity:3];
    if ([self.keysForObjectsWithMoreChanges count] > 0) {
        SPLogVerbose(@"Simperium found %lu objects with more changes to send (%@)", (unsigned long)[self.keysForObjectsWithMoreChanges count], bucket.name);
        
        NSMutableSet *keysProcessed = [NSMutableSet setWithCapacity:self.keysForObjectsWithMoreChanges.count];
        // Create changes for any objects that have more changes
        for (NSString *key in self.keysForObjectsWithMoreChanges) {
            // If there are already changes pending, don't add any more
            // Importantly, this prevents a potential mutation of keysForObjectsWithMoreChanges in processLocalObjectWithKey:later:
            if ([self.changesPending objectForKey: key] != nil)
                continue;
            
            NSDictionary *change = [self processLocalObjectWithKey:key bucket:bucket later:NO];
            
            if (change) {
                [self.changesPending setObject:change forKey:key];
                [newChangesPending addObject:change];
            }
            [keysProcessed addObject:key];
        }
		
        // Clear any keys that were processed into pending changes
        [self.keysForObjectsWithMoreChanges minusSet:keysProcessed];

		// Persist pending changes
		[self.changesPending save];
    }
    
    [self.keysForObjectsWithMoreChanges save];
    
    // TODO: to fix duplicate send, make this return only changes for keysProcessed?
    return newChangesPending;
}


- (int)numChangesPending {
    return (int)[self.changesPending count];
}

- (int)numKeysForObjectsWithMoreChanges {
    return (int)[self.keysForObjectsWithMoreChanges count];
}

- (NSArray*)exportPendingChanges {
	
	// This routine shall be used for debugging purposes!
	NSMutableArray* pendings = [NSMutableArray array];
	for(NSDictionary* change in self.changesPending.allValues) {
				
		NSMutableDictionary* export = [NSMutableDictionary dictionary];
		
		[export setObject:[change[CH_KEY] copy] forKey:CH_KEY];				// Entity Id
		[export setObject:[change[CH_LOCAL_ID] copy] forKey:CH_LOCAL_ID];	// Change Id: ccid
		
		// Start Version is not available for newly inserted objects
		NSString* startVersion = change[CH_START_VERSION];
		if(startVersion) {
			[export setObject:[startVersion copy] forKey:CH_START_VERSION];
		}
		
		[pendings addObject:export];
	}
	
	return pendings;
}

@end
