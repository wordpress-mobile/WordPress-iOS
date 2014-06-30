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
#import "NSError+Simperium.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static SPLogLevels logLevel			= SPLogLevelsInfo;

static int const SPChangeProcessorMaxPendingChanges	= 200;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPChangeProcessor()
@property (nonatomic, strong, readwrite) NSString						*label;
@property (nonatomic, strong, readwrite) NSString                       *clientID;
@property (nonatomic, strong, readwrite) SPPersistentMutableDictionary	*changesPending;
@property (nonatomic, strong, readwrite) SPPersistentMutableSet			*keysForObjectsWithMoreChanges;
@property (nonatomic, strong, readwrite) SPPersistentMutableSet			*keysForObjectsToDelete;
@property (nonatomic, strong, readwrite) SPPersistentMutableSet			*keysForObjectsWithPendingRetry;
@end


#pragma mark ====================================================================================
#pragma mark SPChangeProcessor
#pragma mark ====================================================================================

@implementation SPChangeProcessor

- (id)initWithLabel:(NSString *)label clientID:(NSString *)clientID {
    
    NSAssert(clientID, @"ChangeProcessor should be initialized with a valid clientID");
    
    if ((self = [super init])) {
        self.label                          = label;
        self.clientID                       = clientID;
        
        self.changesPending                 = [SPPersistentMutableDictionary loadDictionaryWithLabel:label];
		
        NSString *moreKey                   = [NSString stringWithFormat:@"keysForObjectsWithMoreChanges-%@", label];
        self.keysForObjectsWithMoreChanges  = [SPPersistentMutableSet loadSetWithLabel:moreKey];
		
        NSString *retryKey                  = [NSString stringWithFormat:@"keysForObjectsWithPendingRetry-%@", label];
        self.keysForObjectsWithPendingRetry = [SPPersistentMutableSet loadSetWithLabel:retryKey];
        
        NSString *deleteKey = [NSString stringWithFormat:@"keysForObjectsToDelete-%@", label];
        self.keysForObjectsToDelete = [SPPersistentMutableSet loadSetWithLabel:deleteKey];
		
        [self migratePendingChangesIfNeeded];
    }
    
    return self;
}

- (void)reset {
    [self.changesPending removeAllObjects];
    [self.keysForObjectsWithMoreChanges removeAllObjects];
	[self.keysForObjectsWithPendingRetry removeAllObjects];
    [self.keysForObjectsToDelete removeAllObjects];
	
	[self.changesPending save];
    [self.keysForObjectsWithMoreChanges save];
	[self.keysForObjectsWithPendingRetry save];
    [self.keysForObjectsToDelete save];
}


#pragma mark ====================================================================================
#pragma mark Private Helpers: Remote changes
#pragma mark ====================================================================================

- (BOOL)processRemoteError:(NSDictionary *)change bucket:(SPBucket *)bucket error:(NSError **)error {

    NSAssert([change isKindOfClass:[NSDictionary class]],  @"Empty change");
    NSAssert([bucket isKindOfClass:[SPBucket class]],      @"Empty Bucket");

    if (!change[CH_ERROR]) {
        return NO;
    }
    
    long errorCode          = [change[CH_ERROR] integerValue];
    long wrappedCode        = SPProcessorErrorsClientError;
    NSString *description   = @"";
    
    switch (errorCode) {
        case CH_ERRORS_DUPLICATE:
            {
                wrappedCode = SPProcessorErrorsSentDuplicateChange;
                description = @"Duplicate Change";
            }
            break;
            
        case CH_ERRORS_BAD_VERSION:
        case CH_ERRORS_EXPECTATION_FAILED:
        case CH_ERRORS_INVALID_DIFF:
            {
                wrappedCode = SPProcessorErrorsSentInvalidChange;
                description = @"Invalid Change";
            }
            break;
            
        case CH_ERRORS_THRESHOLD:
        case CH_ERRORS_INVALID_SCHEMA:
        case CH_ERRORS_INVALID_PERMISSION:
        case CH_ERRORS_NOT_FOUND:
        case CH_ERRORS_EMPTY_CHANGE:
        case CH_ERRORS_DOCUMENT_TOO_lARGE:
        default:
            {
                BOOL isServerError = (errorCode >= CH_SERVER_ERROR_RANGE.location && errorCode < (CH_SERVER_ERROR_RANGE.location + CH_SERVER_ERROR_RANGE.length));
                
                if (isServerError) {
                    wrappedCode = SPProcessorErrorsServerError;
                    description = @"Server Error";
                } else {
                    wrappedCode = SPProcessorErrorsClientError;
                    description = @"Client Error";
                }
            }
            break;
    }
    
    if (error) {
        NSString *wrappedDescription = [NSString stringWithFormat:@"%@ : %d", description, (int)errorCode];
        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:wrappedCode description:wrappedDescription];
    }
    
    return YES;
}

- (BOOL)processRemoteDeleteWithKey:(NSString*)simperiumKey bucket:(SPBucket *)bucket objectWasFound:(BOOL)objectWasFound
                             error:(NSError **)error {
    
	// REMOVE operation
	// If the object still exists in our local storage (no matter if this is an ACK, or remote deletion), proceed nuking it
	if (objectWasFound) {
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

// TODO:
//      - Split this method into processRemoteModify and processRemoteInsertion
//      - This method should receive the coreData context + object, so we prevent double fetching
//      - Once the above are implemented, move the 'begin/finish'SafeSection calls to the caller, and nuke duplicated code, PLEASE!
//      - Nuke ProcessorRequestsReindexingNotification. That should be handled by the processRemoteChanges error handler block
//
- (BOOL)processRemoteModifyWithKey:(NSString *)simperiumKey bucket:(SPBucket *)bucket change:(NSDictionary *)change
					  acknowledged:(BOOL)acknowledged clientMatches:(BOOL)clientMatches error:(NSError **)error {
    
    id<SPStorageProvider> storage = [bucket.storage threadSafeStorage];
	[storage beginSafeSection];
	
    id<SPDiffable> object = [storage objectForKey:simperiumKey bucketName:bucket.name];
	
    BOOL newlyAdded = NO;
    
    // MODIFY operation
    if (!object) {
		// If the change was sent by this very same client, and the object isn't available, don't add it.
		// It Must have been locally deleted before the confirmation got through!
		if (clientMatches) {
            if (error) {
                *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:SPProcessorErrorsReceivedZombieChange description:nil];
            }
			[storage finishSafeSection];
			return NO;
		}
		
        // It doesn't exist yet, so ADD it
        newlyAdded = YES;
		
        // Create the new object
        object = [storage insertNewObjectForBucketName:bucket.name simperiumKey:simperiumKey];
        
        // Remember this object's ghost for future diffing
        // Send nil member data because it'll get loaded below
        SPGhost *ghost  = [[SPGhost alloc] initWithKey:[object simperiumKey] memberData:nil];
        ghost.version   = @"0";
        object.ghost    = ghost;
        
        // If this wasn't just an ack, send a notification and load the data
        SPLogVerbose(@"Simperium non-local ADD ENTITY received %@", object.simperiumKey);
    }
    
    // Another hack since 'ghost' isn't transient: check for fault and forcefire if necessary
    [object willBeRead];
    
    // Make sure the expected last change matches the actual last change
    NSString *oldVersion	= [object.ghost version];
    NSString *startVersion	= change[CH_START_VERSION];
    NSString *endVersion	= change[CH_END_VERSION];
    
    // Store versions as strings, but if they come off the wire as numbers, then handle that too
    if ([startVersion isKindOfClass:[NSNumber class]]) {
        startVersion = [NSString stringWithFormat:@"%ld", (long)[startVersion integerValue]];
	}
	
    if ([endVersion isKindOfClass:[NSNumber class]]) {
        endVersion = [NSString stringWithFormat:@"%ld", (long)[endVersion integerValue]];
    }
	
    // It already exists, now MODIFY it
    if (!object.ghost) {
        SPLogWarn(@"Simperium warning: received change for unknown entity (%@): %@", bucket.name, simperiumKey);
        if (error) {
            *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:SPProcessorErrorsReceivedUnknownChange description:nil];
        }
        [storage finishSafeSection];
        return NO;
    }
    
    // If the local version matches the remote endVersion, don't process this change: it's a dupe message.
    // Processing aside, let's advance the bucket's CV, and return true
    if ([object.ghost.version isEqual:endVersion]) {
        [storage finishSafeSection];
        return YES;
    }
	
    SPLogVerbose(@"Simperium received version = %@, previous version = %@", startVersion, oldVersion);
    // If the versions are equal or there's no start version (new object), process the change
    if (startVersion == nil || [oldVersion isEqualToString:startVersion]) {
        // Remember the old ghost
        SPGhost *oldGhost       = [object.ghost copy];
        NSDictionary *diff      = change[CH_VALUE];
        NSError *theError       = nil;
        
        // Apply the diff to the ghost and store the new data in the object's ghost
        if (![bucket.differ applyGhostDiffFromDictionary:diff toObject:object error:&theError]) {
            SPLogError(@"Simperium error during applyGhostDiff: %@", theError.localizedDescription);
            if (error) {
                *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:SPProcessorErrorsReceivedInvalidChange description:theError.description];
            }
            [storage finishSafeSection];
            return NO;
        }
        
        object.ghost.version = endVersion;
        
        // Slight hack to ensure Core Data realizes the object has changed and needs a save
        NSString *ghostDataCopy = [[[object.ghost dictionary] sp_JSONString] copy];
        object.ghostData        = ghostDataCopy;
        
        SPLogVerbose(@"Simperium MODIFIED ghost version %@ (%@-%@)", endVersion, bucket.name, self.label);
        
        // If it wasn't an ack, then local data needs to be updated and the app needs to be notified
        if (!acknowledged && !newlyAdded) {
            SPLogVerbose(@"Simperium non-local MODIFY ENTITY received");
            NSDictionary *oldDiff = [bucket.differ diffFromDictionary:oldGhost.memberData toObject:object];
            if (oldDiff.count) {
                // The local client version changed in the meantime, so transform the diff before applying it
                SPLogVerbose(@"Simperium applying transform to diff: %@", diff);
                diff = [bucket.differ transform:object diff:oldDiff oldDiff:diff oldGhost:oldGhost error:&theError];
                if (theError) {
                    SPLogError(@"Simperium error during diff transform: %@", theError.localizedDescription);
                    if (error) {
                        *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:SPProcessorErrorsReceivedInvalidChange description:theError.description];
                    }
                    [storage finishSafeSection];
                    return NO;
                }
                
                // Load from the ghost data so the subsequent diff is applied to the correct data
                // Do an extra check in case there was a problem with the transform/diff, e.g. if a client's own change was misinterpreted
                // as another client's change, in other words not properly acknowledged.
                if (diff.count) {
                    [object loadMemberData:object.ghost.memberData];
                } else {
                    SPLogVerbose(@"Simperium transform resulted in empty diff (invalid ack?)");
				}
            }
        }
        
        // Apply the diff to the object itself
        if (!acknowledged && diff.count) {
            SPLogVerbose(@"Simperium applying diff: %@", diff);
            
            if (![bucket.differ applyDiffFromDictionary:diff toObject:object error:&theError]) {
                SPLogError(@"Simperium error during applyDiff: %@", theError.localizedDescription);
                if (error) {
                    *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:SPProcessorErrorsReceivedInvalidChange description:theError.description];
                }
                [storage finishSafeSection];
                return NO;
            }
        }
        
        [storage save];
		
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableDictionary *userInfo = [@{
                @"bucketName" : bucket.name,
                @"keys"       : [NSSet setWithObject:simperiumKey]
            } mutableCopy];
            
            NSString *notificationName;
            if (newlyAdded) {
                notificationName = ProcessorDidAddObjectsNotification;
            } else if (acknowledged) {
                notificationName = ProcessorDidAcknowledgeObjectsNotification;
            } else {
                notificationName = ProcessorDidChangeObjectNotification;                
                [userInfo setObject:diff.allKeys forKey:@"changedMembers"];
            }
			
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:bucket userInfo:userInfo];
        });
        
    } else {
        SPLogWarn(@"Simperium warning: couldn't apply change due to version mismatch (duplicate? start %@, old %@): change %@", startVersion, oldVersion, change);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ProcessorRequestsReindexingNotification object:bucket];
        });
    }
	
	[storage finishSafeSection];
	
    return YES;
}

- (BOOL)processRemoteChange:(NSDictionary *)change bucket:(SPBucket *)bucket error:(NSError **)error {
	
    NSAssert([NSThread isMainThread] == NO, @"This should not get called on the main thread");
    NSAssert(self.clientID,                 @"Missing clientID");
    NSAssert(change[CH_ERROR] == nil,       @"This should not be called if the change has an error");
	
    // Create a new context (to be thread-safe) and fetch the entity from it
    NSString *key                   = [self keyWithoutNamespaces:change bucket:bucket];
    id<SPStorageProvider>storage    = [bucket.storage threadSafeStorage];
    
    [storage beginSafeSection];
	
    NSString *operation         = change[CH_OPERATION];
    NSString *changeVersion     = change[CH_CHANGE_VERSION];
    NSString *changeClientID    = change[CH_CLIENT_ID];
    id<SPDiffable> object       = [storage objectForKey:key bucketName:bucket.name];
    
    SPLogVerbose(@"Simperium client %@ received change (%@) %@: %@", self.clientID, bucket.name, changeClientID, change);
	
	// Process
    BOOL objectWasFound         = (object != nil);
    BOOL clientMatches          = ([changeClientID compare:self.clientID] == NSOrderedSame);
    BOOL remove                 = (operation && [operation compare:CH_REMOVE] == NSOrderedSame);
    BOOL acknowledged           = ([self awaitingAcknowledgementForKey:key] && clientMatches);
    
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
	[storage finishSafeSection];
		
    if (remove && (objectWasFound || acknowledged)) {
        return [self processRemoteDeleteWithKey:key bucket:bucket objectWasFound:objectWasFound error:error];
    } else if (operation && [operation compare: CH_MODIFY] == NSOrderedSame) {
        return [self processRemoteModifyWithKey:key bucket:bucket change:change acknowledged:acknowledged clientMatches:clientMatches error:error];
    }
	
	// Invalid
	SPLogError(@"Simperium error (%@), received an invalid change for (%@): %@", bucket.name, key, change);
    return NO;
}


#pragma mark ====================================================================================
#pragma mark Remote Changes
#pragma mark ====================================================================================

- (void)notifyOfRemoteChanges:(NSArray *)changes bucket:(SPBucket *)bucket {
    
    NSAssert([NSThread isMainThread], @"This should get called on the main thread!");
    
    NSMutableSet *changedKeys = [NSMutableSet setWithCapacity:changes.count];

    for (NSDictionary *change in changes) {
        NSString *key = [self keyWithoutNamespaces:change bucket:bucket];
        if (![self awaitingAcknowledgementForKey:key]) {
            [changedKeys addObject:key];
		}
    }
    
    if (changedKeys.count == 0) {
        return;
    }
    
    NSDictionary *userInfo = @{
        @"bucketName"	: bucket.name,
        @"keys"			: changedKeys
    };
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ProcessorWillChangeObjectsNotification object:bucket userInfo:userInfo];
}

- (void)processRemoteChanges:(NSArray *)changes bucket:(SPBucket *)bucket errorHandler:(SPChangeErrorHandlerBlockType)errorHandler {

    NSAssert([NSThread isMainThread] == NO,            @"This should get called on the processor's queue!");
    NSAssert([bucket isKindOfClass:[SPBucket class]],  @"Invalid Bucket");
    NSAssert(errorHandler,                             @"Please, provide an error handler!");
    
    @autoreleasepool {
        
        for (NSDictionary *change in changes) {
            
            // Process Errors: Halt if needed (critical errors!)
            NSString *key       = [self keyWithoutNamespaces:change bucket:bucket];
            NSString *version   = change[CH_END_VERSION];
            NSError *error      = nil;

            if ([self processRemoteError:change bucket:bucket error:&error]) {
                errorHandler(key, version, error);
                continue;
            }
            
            // Process Changes: this is necessary even if it's an ack, so the ghost data gets set accordingly
            if (![self processRemoteChange:change bucket:bucket error:&error]) {
                errorHandler(key, version, error);
                continue;
            }

            // Persist LastChangeSignature: do it inside the loop in case something happens to abort the loop
            NSString *changeVersion = change[CH_CHANGE_VERSION];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                bucket.lastChangeSignature = changeVersion;
            });
        }
    
        [self.changesPending save];
        
        // Signal that the bucket has been sync'ed (If Needed!)
        if (!bucket.isForceSyncPending || self.changesPending.count) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [bucket signalForceSyncComplete];
        });
    }
}


#pragma mark ====================================================================================
#pragma mark Change Helpers
#pragma mark ====================================================================================

- (void)enqueueObjectForMoreChanges:(NSString *)key bucket:(SPBucket *)bucket {
    NSAssert( [key isKindOfClass:[NSString class]],         @"Missing key" );
    NSAssert( [bucket isKindOfClass:[SPBucket class]],      @"Missing Bucket");
    
	SPLogVerbose(@"Simperium marking object for sending more changes when ready (%@): %@", bucket.name, key);
	[self.keysForObjectsWithMoreChanges addObject:key];
	[self.keysForObjectsWithMoreChanges save];
}

- (void)enqueueObjectDeletion:(NSString *)key bucket:(SPBucket *)bucket {
    NSAssert( [key isKindOfClass:[NSString class]],         @"Missing key" );
    NSAssert( [bucket isKindOfClass:[SPBucket class]],      @"Missing Bucket");
    
    SPLogVerbose(@"Simperium marking object for deletion when ready (%@): %@", bucket.name, key);
    [self.keysForObjectsToDelete addObject:key];
    [self.keysForObjectsToDelete save];
}

- (void)enqueueObjectForRetry:(NSString *)key bucket:(SPBucket *)bucket overrideRemoteData:(BOOL)overrideRemoteData {
    
    NSAssert( [key isKindOfClass:[NSString class]],     @"Missing change" );
    NSAssert( [bucket isKindOfClass:[SPBucket class]],  @"Missing Bucket");
    
    id<SPStorageProvider>threadSafeStorage = [bucket.storage threadSafeStorage];
    [threadSafeStorage beginSafeSection];
    
    id<SPDiffable>object    = [threadSafeStorage objectForKey:key bucketName:bucket.name];
    NSDictionary *oldChange = [self.changesPending objectForKey:key];
    
    // Was the object remotely nuked?
    if (!object && ![oldChange[CH_OPERATION] isEqualToString:CH_REMOVE]) {
        [self.changesPending removeObjectForKey:key];
        [threadSafeStorage finishSafeSection];
        return;
    }
    
    // Do we need to repost with the whole data?
    if (object && overrideRemoteData) {
        // Fire fault
        NSMutableDictionary *newChange = [oldChange mutableCopy];
        newChange[CH_DATA] = [object dictionary];
        [self.changesPending setObject:newChange forKey:key];
    }
    
    [threadSafeStorage finishSafeSection];
    
    [self.keysForObjectsWithPendingRetry addObject:key];
    [self.keysForObjectsWithPendingRetry save];
}

- (void)discardPendingChanges:(NSString *)key bucket:(SPBucket *)bucket {
    
    NSAssert( [key isKindOfClass:[NSString class]],     @"Missing change" );
    NSAssert( [bucket isKindOfClass:[SPBucket class]],  @"Missing Bucket");
    
    [self.changesPending removeObjectForKey:key];
}


#pragma mark ====================================================================================
#pragma mark Local changes
#pragma mark ====================================================================================

- (NSArray *)processLocalObjectsWithKeys:(NSSet *)keys bucket:(SPBucket *)bucket {
    
    NSMutableArray *changes         = [NSMutableArray arrayWithCapacity:keys.count];
    NSMutableSet *keysNotFound      = [keys mutableCopy];
    id<SPStorageProvider> storage   = [bucket.storage threadSafeStorage];
    
	[storage beginSafeSection];
    NSArray *objects                = [storage objectsForKeys:keys bucketName:bucket.name];
    
    for (id<SPDiffable> object in objects) {
        
        NSAssert([object conformsToProtocol:@protocol(SPDiffable)], nil);
        SPLogVerbose(@"Simperium processing local object changes (%@): %@", bucket.name, object.simperiumKey);
        
        // Good! this object wasn't nuked
        [keysNotFound removeObject:object.simperiumKey];
        
        // Pending Changes: Let's mark this entity and come back later to get the changes
        if ([self.changesPending containsObjectForKey:object.simperiumKey]) {
            [self enqueueObjectForMoreChanges:object.simperiumKey bucket:bucket];
            continue;
        }
        
        NSDictionary *newData = nil;
        
        if (object.ghost != nil && [object.ghost memberData] != nil) {
            // This object has already been synced in the past and has a server ghost, so we're modifying the object
            newData = [bucket.differ diffFromDictionary:object.ghost.memberData toObject:object];
            SPLogVerbose(@"Simperium entity diff found %lu changed members", (unsigned long)newData.count);
        } else  {
            newData = [bucket.differ diffForAddition:object];
            SPLogVerbose(@"Simperium local ADD detected, creating diff...");
        }
        
        if (newData.count == 0) {
            SPLogVerbose(@"Simperium warning: no difference in call to sendChanges (%@): %@", bucket.name, object.simperiumKey);
        } else {
            NSDictionary *change = [self createChangeForKey:object.simperiumKey operation:CH_MODIFY version:object.ghost.version data:newData];
            [self.changesPending setObject:change forKey:object.simperiumKey];
            [changes addObject:change];
        }
    }
    
    // Objects Not Found: they were likely previously deleted, in which case the change being processed here is no longer relevant
    for (NSString *keyNotFound in keysNotFound) {
        SPLogWarn(@"Simperium warning: couldn't processLocalObjectWithKey %@ because the object no longer exists", keyNotFound);
        [self.changesPending removeObjectForKey:keyNotFound];
        [self.keysForObjectsWithMoreChanges removeObject:keyNotFound];
    }
    
    // Persist!
    if (keysNotFound.count) {
        [self.keysForObjectsWithMoreChanges save];
    }
    
    [self.changesPending save];
	[storage finishSafeSection];
    
    return changes;
}
    
- (NSArray *)processLocalDeletionsWithKeys:(NSSet *)keys {
    NSMutableArray *changes = [NSMutableArray array];
    
    for (NSString *key in keys) {
        NSAssert([key isKindOfClass:[NSString class]], nil);
        
        NSDictionary *change = [self createChangeForKey:key operation:CH_REMOVE version:nil data:nil];
        [self.changesPending setObject:change forKey:key];
        [changes addObject:change];
    }
    
    [self.changesPending save];
    
    return changes;
}

- (NSArray *)processLocalBucketsDeletion:(NSSet *)buckets {
    
    NSMutableArray *changes = [NSMutableArray array];
    for (SPBucket *bucket in buckets) {
        NSAssert([bucket isKindOfClass:[SPBucket class]], nil);
        
        NSDictionary *change = [self createChangeForKey:bucket.name operation:CH_EMPTY version:nil data:nil];
        [changes addObject:change];
    }
    
	return changes;
}

- (void)enumeratePendingChangesForBucket:(SPBucket *)bucket block:(SPChangeEnumerationBlockType)block {

	NSInteger pendingCount = self.changesPending.count;
    if (pendingCount == 0) {
		return;
	}
	
	SPLogVerbose(@"Simperium found %lu objects with pending changes to send (%@)", (unsigned long)pendingCount, bucket.name);

	for (NSString *key in self.changesPending.allKeys) {
		NSDictionary* change = [self.changesPending objectForKey:key];
		if (change) {
			block(change);
		}
	}
}

- (void)enumerateQueuedChangesForBucket:(SPBucket *)bucket block:(SPChangeEnumerationBlockType)block {
    
    NSInteger limit = MAX( SPChangeProcessorMaxPendingChanges - self.changesPending.count, 0);
    NSUInteger queueCount = self.keysForObjectsWithMoreChanges.count;
    
    if (queueCount == 0 || limit <= 0) {
		return;
	}

	SPLogVerbose(@"Simperium found %lu objects with more changes to send (%@)", (unsigned long)queueCount, bucket.name);
    
    // Filter out keys with pending changes: prevents a potential mutation of keysForObjectsWithMoreChanges in processLocalObjectWithKey:later:
	NSMutableSet *processedKeys	= [NSMutableSet setWithCapacity:limit];
    
    for (NSString *key in self.keysForObjectsWithMoreChanges) {

        if (processedKeys.count >= limit) {
            break;
		}
        
        if (![self.changesPending containsObjectForKey:key]) {
            [processedKeys addObject:key];
        }
	}
    
    NSArray *changes = [self processLocalObjectsWithKeys:processedKeys bucket:bucket];
    
	for (NSDictionary *change in changes) {
        block(change);
	}
	
	[self.keysForObjectsWithMoreChanges minusSet:processedKeys];
    [self.keysForObjectsWithMoreChanges save];
}

- (void)enumerateQueuedDeletionsForBucket:(SPBucket*)bucket block:(SPChangeEnumerationBlockType)block {
    
    NSInteger limit = MAX( SPChangeProcessorMaxPendingChanges - self.changesPending.count, 0);
    NSUInteger queueCount = self.keysForObjectsToDelete.count;
    
    if (queueCount == 0 || limit <= 0) {
        return;
    }
    
    SPLogVerbose(@"Simperium found %lu objects to delete (%@)", (unsigned long)queueCount, bucket.name);
    
    NSMutableSet *processedKeys	= [NSMutableSet setWithCapacity:limit];
    
    for (NSString *key in self.keysForObjectsToDelete) {
        
        if (processedKeys.count >= limit) {
            break;
        }
        [processedKeys addObject:key];
    }
    
    NSArray *changes = [self processLocalDeletionsWithKeys:processedKeys];
    
    for (NSDictionary *change in changes) {
        block(change);
    }
    
    [self.keysForObjectsToDelete minusSet:processedKeys];
    [self.keysForObjectsToDelete save];
}

- (void)enumerateRetryChangesForBucket:(SPBucket *)bucket block:(SPChangeEnumerationBlockType)block {
	
    NSInteger retryCount = self.keysForObjectsWithPendingRetry.count;
	if (retryCount == 0) {
		return;
	}
	
	SPLogVerbose(@"Simperium found %lu objects in the retry queue (%@)", (unsigned long)retryCount, bucket.name);
	NSMutableSet *processedKeys = [NSMutableSet set];
    
	for (NSString *key in self.keysForObjectsWithPendingRetry) {
		NSDictionary* change = [self.changesPending objectForKey:key];
		if (change) {
			block(change);
		}
		
		[processedKeys addObject:key];
	}
	
	[self.keysForObjectsWithPendingRetry minusSet:processedKeys];
	[self.keysForObjectsWithPendingRetry save];
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

- (int)numKeysForObjectToDelete {
    return (int)self.keysForObjectsToDelete.count;
}

- (BOOL)reachedMaxPendings {
	return (self.changesPending.count >= SPChangeProcessorMaxPendingChanges);
}


#pragma mark ====================================================================================
#pragma mark Private Helpers: Changeset Generation + metadata
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
