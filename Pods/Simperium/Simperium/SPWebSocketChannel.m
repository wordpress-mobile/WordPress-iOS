//
//  SPWebSocketChannel.m
//  Simperium
//
//  Created by Michael Johnston on 12-08-09.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import "SPWebSocketChannel.h"

#define DEBUG_REQUEST_STATUS
#import "SPEnvironment.h"
#import "Simperium.h"
#import "SPDiffer.h"
#import "SPBucket+Internals.h"
#import "SPStorage.h"
#import "SPUser.h"
#import "SPChangeProcessor.h"
#import "SPIndexProcessor.h"
#import "SPMember.h"
#import "SPGhost.h"
#import "SPWebSocketInterface.h"
#import "JSONKit+Simperium.h"
#import "NSString+Simperium.h"
#import "SPLogger.h"
#import "SRWebSocket.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static int const SPWebsocketIndexPageSize			= 500;
static int const SPWebsocketIndexBatchSize			= 10;
static int const SPWebsocketErrorAuthFailed			= 401;
static NSString* const SPWebsocketErrorMark			= @"{";
static NSString* const SPWebsocketErrorKey			= @"code";

static BOOL useNetworkActivityIndicator				= 0;
static SPLogLevels logLevel							= SPLogLevelsInfo;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPWebSocketChannel()
@property (nonatomic, weak)   Simperium				*simperium;
@property (nonatomic, strong) NSMutableArray		*responseBatch;
@property (nonatomic, strong) NSMutableDictionary	*versionsWithErrors;
@property (nonatomic, copy)   NSString				*clientID;
@property (nonatomic, assign) NSInteger				retryDelay;
@property (nonatomic, assign) NSInteger				objectVersionsPending;
@property (nonatomic, assign) BOOL					indexing;
@property (nonatomic, assign) BOOL					retrievingObjectHistory;
@end


#pragma mark ====================================================================================
#pragma mark SPWebSocketChannel
#pragma mark ====================================================================================

@implementation SPWebSocketChannel

+ (void)updateNetworkActivityIndictator {
    // For now at least, don't display the indicator when using WebSockets
}

+ (void)setNetworkActivityIndicatorEnabled:(BOOL)enabled {
    useNetworkActivityIndicator = enabled;
}

- (id)initWithSimperium:(Simperium *)s clientID:(NSString *)cid {
	if ((self = [super init])) {
        self.simperium = s;
        self.indexArray = [NSMutableArray arrayWithCapacity:200];
        self.clientID = cid;
        self.versionsWithErrors = [NSMutableDictionary dictionaryWithCapacity:3];
    }
	
	return self;
}

- (void)sendChangesForBucket:(SPBucket *)bucket onlyQueuedChanges:(BOOL)onlyQueuedChanges completionBlock:(void(^)())completionBlock {
    // This gets called after remote changes have been handled in order to pick up any local changes that happened in the meantime
    dispatch_async(bucket.processorQueue, ^{
		[bucket.changeProcessor enumeratePendingChanges:bucket onlyQueuedChanges:onlyQueuedChanges block:^(NSDictionary *change) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (!self.started) {
					return;
				}
				
				NSString *jsonStr = [change sp_JSONString];
				NSString *message = [NSString stringWithFormat:@"%d:c:%@", self.number, jsonStr];
				SPLogVerbose(@"Simperium sending change (%@-%@) %@",bucket.name, bucket.instanceLabel, message);
				[self.webSocketManager send:message];
			});
		}];
		
		// All done!
		if (completionBlock) {
			dispatch_async(dispatch_get_main_queue(), ^{
				completionBlock();
			});
		}
    });
}

- (void)sendChange:(NSDictionary *)change forKey:(NSString *)key bucket:(SPBucket *)bucket {
    SPLogVerbose(@"Simperium adding pending change (%@): %@", self.name, key);
    
    [bucket.changeProcessor processLocalChange:change key:key];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *jsonStr = [change sp_JSONString];
        NSString *message = [NSString stringWithFormat:@"%d:c:%@", self.number, jsonStr];
        SPLogVerbose(@"Simperium sending change (%@-%@) %@",bucket.name, bucket.instanceLabel, message);
        [self.webSocketManager send:message];
    });
}

- (void)sendObjectDeletion:(id<SPDiffable>)object {
    NSString *key = [object simperiumKey];
    SPLogVerbose(@"Simperium sending entity DELETION change: %@/%@", self.name, key);
    
    // Send the deletion change (which will also overwrite any previous unsent local changes)
    // This could cause an ACK to fail if the deletion is registered before a previous change was ACK'd, but that should be OK since the object will be deleted anyway.
    
    if (key == nil) {
        SPLogWarn(@"Simperium received DELETION request for nil key");
        return;
    }
    
    dispatch_async(object.bucket.processorQueue, ^{
        NSDictionary *change = [object.bucket.changeProcessor processLocalDeletionWithKey: key];
        [self sendChange: change forKey: key bucket:object.bucket];
    });
}

- (void)sendObjectChanges:(id<SPDiffable>)object {
    // Consider being more careful about faulting here (since only the simperiumKey is needed)
    NSString *key = [object simperiumKey];
    if (key == nil) {
        SPLogWarn(@"Simperium tried to send changes for an object with a nil simperiumKey (%@)", self.name);
        return;
    }
    
    dispatch_async(object.bucket.processorQueue, ^{
		@autoreleasepool {
			NSDictionary *change = [object.bucket.changeProcessor processLocalObjectWithKey:key bucket:object.bucket later:_indexing || !_started];
			if (change) {
				[self sendChange: change forKey: key bucket:object.bucket];
			}
		}
    });
}

- (void)sendBucketStatus:(SPBucket *)bucket {

	NSDictionary *response = [bucket exportStatus];
	NSString *jsonStr = [response sp_JSONString];
	NSString *message = [NSString stringWithFormat:@"%d:index:%@", self.number, jsonStr];
	
	SPLogVerbose(@"Simperium sending Bucket Internal State (%@-%@) %@", bucket.name, bucket.instanceLabel, message);
	[self.webSocketManager send:message];
}

- (void)removeAllBucketObjects:(SPBucket *)bucket {
	// TODO: Can we convert this message into something like this, perhaps?: 'd:bucket_name'
	NSDictionary *rawMessage =	@{
		@"o"		: @"EMPTY",
		@"id"		: bucket.name,
		@"ccid"		: [NSString sp_makeUUID],
		@"clientid"	: self.simperium.clientID
	};
	
	NSString *message = [NSString stringWithFormat:@"%d:c:%@", self.number, [rawMessage sp_JSONString]];
	SPLogVerbose(@"Simperium deleting all Bucket Objects (%@-%@) %@", bucket.name, bucket.instanceLabel, message);
	
	[self.webSocketManager send:message];
}

- (void)startProcessingChangesForBucket:(SPBucket *)bucket {
    __block int numChangesPending;
    __block int numKeysForObjectsWithMoreChanges;
    dispatch_async(bucket.processorQueue, ^{
		numChangesPending = [bucket.changeProcessor numChangesPending];
		numKeysForObjectsWithMoreChanges = [bucket.changeProcessor numKeysForObjectsWithMoreChanges];

		dispatch_async(dispatch_get_main_queue(), ^{
			if (!self.started) {
				return;
			}
			
			// Start getting changes from the last cv
			NSString *getMessage = [NSString stringWithFormat:@"%d:cv:%@", self.number, bucket.lastChangeSignature ? bucket.lastChangeSignature : @""];
			SPLogVerbose(@"Simperium client %@ sending cv %@", self.simperium.clientID, getMessage);
			[self.webSocketManager send:getMessage];
			
			if (numChangesPending > 0 || numKeysForObjectsWithMoreChanges > 0) {
				// There are also offline changes; send them right away
				// This needs to happen after the above cv is sent, otherwise acks will arrive prematurely if there
				// have been remote changes that need to be processed first
				SPLogVerbose(@"Simperium sending %u pending offline changes (%@) plus %d objects with more", numChangesPending, self.name, numKeysForObjectsWithMoreChanges);
				[self sendChangesForBucket:bucket onlyQueuedChanges:NO completionBlock:nil];
			}
		});
    });
}

- (int)nextRetryDelay {
//    int currentDelay = retryDelay;
//    retryDelay *= 2;
//    if (retryDelay > 24)
//        retryDelay = 24;
    
//    return currentDelay;
    return 2;
}

- (void)resetRetryDelay {
    self.retryDelay = 2;
}

- (void)handleAuthResponse:(NSString *)responseString bucket:(SPBucket *)bucket {
		
	// Does the response have a payload?
	if ([responseString rangeOfString:SPWebsocketErrorMark].location == 0) {
		SPLogWarn(@"Simperium received unexpected auth response: %@", responseString);
		
		NSError *error = nil;
		NSDictionary *authPayload = [responseString sp_objectFromJSONStringWithError:&error];
		
		if ( [authPayload isKindOfClass:[NSDictionary class]] ) {
			if ( [authPayload[SPWebsocketErrorKey] isEqualToNumber:@(SPWebsocketErrorAuthFailed)] ) {
				[[NSNotificationCenter defaultCenter] postNotificationName:SPAuthenticationDidFail object:self];
			}
		}
		
	// Everything looks good!
	} else {
		self.started = YES;
		self.simperium.user.email = responseString;
		
		if (bucket.lastChangeSignature == nil) {
			[self requestLatestVersionsForBucket:bucket];
		} else {
			[self startProcessingChangesForBucket:bucket];
		}
	}
}

- (void)handleRemoteChanges:(NSArray *)changes bucket:(SPBucket *)bucket {

	// Signal that the bucket was sync'ed. We need this, in case the sync was manually triggered
	if (changes.count == 0) {
		[bucket bucketDidSync];
		return;
	}
		
	SPLogVerbose(@"Simperium handling changes %@", changes);
	
	// Changing entities and saving the context will clear Core Data's updatedObjects. Stash them so
	// sync will still work for any unsaved changes.
	[bucket.storage stashUnsavedObjects];
	
	dispatch_async(bucket.processorQueue, ^{
		if (!self.started) {
			return;
		}
		
		BOOL needsRepost = [bucket.changeProcessor processRemoteResponseForChanges:changes bucket:bucket];
		[bucket.changeProcessor processRemoteChanges:changes bucket:bucket clientID:self.clientID];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			// Note #1: After remote changes have been processed, check to see if any local changes were attempted (and
			//			queued) in the meantime, and send them.
			
			// Note #2: If we need to repost, we'll need to re-send everything. Not just the queued changes.
			[self sendChangesForBucket:bucket onlyQueuedChanges:!needsRepost completionBlock:nil];
		});
	});
}

#pragma mark Index handling

- (void)requestLatestVersionsForBucket:(SPBucket *)bucket mark:(NSString *)mark {
    if (!self.simperium.user) {
        SPLogError(@"Simperium critical error: tried to retrieve index with no user set");
        return;
    }

	// Get an index of all objects and fetch their latest versions
    self.indexing = YES;
    
    NSString *message = [NSString stringWithFormat:@"%d:i::%@::%d", self.number, mark ? mark : @"", SPWebsocketIndexPageSize];
    SPLogVerbose(@"Simperium requesting index (%@): %@", self.name, message);
    [self.webSocketManager send:message];
}

- (void)requestLatestVersionsForBucket:(SPBucket *)bucket {
    // Multiple errors could try to trigger multiple index refreshes
    if (self.indexing) {
        return;
	}
	
	self.indexing = YES;
    
    // Send any pending changes first
    // This could potentially lead to some duplicate changes being sent if there are some that are awaiting
    // acknowledgment, but the server will safely ignore them
    [self sendChangesForBucket:bucket onlyQueuedChanges:NO completionBlock: ^{
        [self requestLatestVersionsForBucket:bucket mark:nil];
    }];
}

- (void)requestVersionsForKeys:(NSArray *)currentIndexArray bucket:(SPBucket *)bucket {
    // Changing entities and saving the context will clear Core Data's updatedObjects. Stash them so
    // sync will still work later for any unsaved changes.
    // In the time between now and when the index refresh completes, any local changes will get marked
    // since regular syncing is disabled during index retrieval.
    [bucket.storage stashUnsavedObjects];

    if ([bucket.delegate respondsToSelector:@selector(bucketWillStartIndexing:)]) {
        [bucket.delegate bucketWillStartIndexing:bucket];
	}

    self.responseBatch = [NSMutableArray arrayWithCapacity:SPWebsocketIndexBatchSize];

    // Get all the latest versions
    SPLogInfo(@"Simperium processing %lu objects from index (%@)", (unsigned long)[currentIndexArray count], self.name);

    NSArray *indexArrayCopy = [currentIndexArray copy];
    __block int objectRequests = 0;
    dispatch_async(bucket.processorQueue, ^{
        if (self.started) {
            [bucket.indexProcessor processIndex:indexArrayCopy bucket:bucket versionHandler: ^(NSString *key, NSString *version) {
                objectRequests++;

                // For each version that is processed, create a network request
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = [NSString stringWithFormat:@"%d:e:%@.%@", self.number, key, version];
                    SPLogVerbose(@"Simperium sending object request (%@): %@", self.name, message);
                    [self.webSocketManager send:message];
                });
            }];

            dispatch_async(dispatch_get_main_queue(), ^{
                // If no requests need to be queued, then all is good; back to processing
                self.objectVersionsPending = objectRequests;
                if (self.objectVersionsPending == 0) {
                    if (self.nextMark.length > 0)
                    // More index pages to get
                        [self requestLatestVersionsForBucket: bucket mark:self.nextMark];
                    else
                    // The entire index has been retrieved
                        [self allVersionsFinishedForBucket:bucket];
                    return;
                }

                SPLogInfo(@"Simperium enqueuing %ld object requests (%@)", (long)self.objectVersionsPending, bucket.name);
            });
        }
    });
}

- (void)handleIndexResponse:(NSString *)responseString bucket:(SPBucket *)bucket {
	
    SPLogVerbose(@"Simperium received index (%@): %@", self.name, responseString);
	
	if (self.indexing == false) {
		SPLogError(@"ERROR: Index response was NOT expected!");
	}
		
    NSDictionary *responseDict = [responseString sp_objectFromJSONString];
    NSArray *currentIndexArray = [responseDict objectForKey:@"index"];
    id current = [responseDict objectForKey:@"current"];

    // Store versions as strings, but if they come off the wire as numbers, then handle that too
    if ([current isKindOfClass:[NSNumber class]]) {
        current = [NSString stringWithFormat:@"%ld", (long)[current integerValue]];
	}
    self.pendingLastChangeSignature = [current length] > 0 ? [NSString stringWithFormat:@"%@", current] : nil;
    self.nextMark = [responseDict objectForKey:@"mark"];
    
    // Remember all the retrieved data in case there's more to get
    [self.indexArray addObjectsFromArray:currentIndexArray];
	
    // If there's another page, get those too (this will repeat until there are none left)
    if (self.nextMark.length > 0) {
        SPLogVerbose(@"Simperium found another index page mark (%@): %@", self.name, self.nextMark);
        [self requestLatestVersionsForBucket:bucket mark:self.nextMark];
        return;
    }

    // Index retrieval is complete, so get all the versions
    [self requestVersionsForKeys:self.indexArray bucket:bucket];
    [self.indexArray removeAllObjects];
}

- (void)processBatchForBucket:(SPBucket *)bucket {
    if ([self.responseBatch count] == 0) {
        return;
	}

    NSMutableArray *batch = [self.responseBatch copy];
    BOOL firstSync = bucket.lastChangeSignature == nil;
    dispatch_async(bucket.processorQueue, ^{
        if (self.started) {
            [bucket.indexProcessor processVersions: batch bucket:bucket firstSync: firstSync changeHandler:^(NSString *key) {
                // Local version was different, so process it as a local change
                [bucket.changeProcessor processLocalObjectWithKey:key bucket:bucket later:YES];
            }];
            
            // Now check if indexing is complete
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_objectVersionsPending > 0) {
                    _objectVersionsPending--;
				}
                if (_objectVersionsPending == 0) {
                    [self allVersionsFinishedForBucket:bucket];
				}
            });
        }
    });

    [self.responseBatch removeAllObjects];
}

- (void)handleVersionResponse:(NSString *)responseString bucket:(SPBucket *)bucket {
    if ([responseString isEqualToString:@"?"]) {
        SPLogError(@"Simperium error: '?' response during version retrieval (%@)", bucket.name);
        _objectVersionsPending--;
        return;
    }

    // Expected format is: key_here.maybe.with.periods.VERSIONSTRING\n{payload}
    NSRange headerRange = [responseString rangeOfString:@"\n"];
    if (headerRange.location == NSNotFound) {
        SPLogError(@"Simperium error: version header not found during version retrieval (%@)", bucket.name);
        _objectVersionsPending--;
        return;
    }
    
    NSRange keyRange = [responseString rangeOfString:@"." options:NSBackwardsSearch range:NSMakeRange(0, headerRange.location)];
    if (keyRange.location == NSNotFound) {
        SPLogError(@"Simperium error: version key not found during version retrieval (%@)", bucket.name);
        _objectVersionsPending--;
        return;
    }
    
    NSRange versionRange = NSMakeRange(keyRange.location + keyRange.length,
                                       headerRange.location - headerRange.length - keyRange.location);
    
    NSString *key = [responseString substringToIndex:keyRange.location];
    NSString *version = [responseString substringWithRange:versionRange];
    NSString *payload = [responseString substringFromIndex:headerRange.location + headerRange.length];
    SPLogInfo(@"Simperium received version (%@): %@", self.name, responseString);
    
    // With websockets, the data is wrapped up (somewhat annoyingly) in a dictionary, so unwrap it
    // This processing should probably be moved off the main thread (or improved at the protocol level)
    NSDictionary *payloadDict = [payload sp_objectFromJSONString];
    NSDictionary *dataDict = [payloadDict objectForKey:@"data"];
    
    if ([dataDict class] == [NSNull class] || dataDict == nil) {
        // No data
        SPLogError(@"Simperium error: version had no data (%@): %@", bucket.name, key);
        _objectVersionsPending--;
        return;
    }
    
    // All unwrapped, now get it in the format we need for marshaling
    NSString *payloadString = [dataDict sp_JSONString];
    
    // If there was an error previously, unflag it
    [self.versionsWithErrors removeObjectForKey:key];

    // If retrieving object versions (e.g. for going back in time), return the result directly to the delegate
    if (_retrievingObjectHistory) {
        if (--_objectVersionsPending == 0) {
            _retrievingObjectHistory = NO;
		}
        if ([bucket.delegate respondsToSelector:@selector(bucket:didReceiveObjectForKey:version:data:)]) {
            [bucket.delegate bucket:bucket didReceiveObjectForKey:key version:version data:dataDict];
		}
    } else {
        // Otherwise, process the result for indexing
        // Marshal everything into an array for later processing
        NSArray *responseData = [NSArray arrayWithObjects: key, payloadString, version, nil];
        [self.responseBatch addObject:responseData];

        // Batch responses for more efficient processing
        // (process the last handful individually though)
        if (self.responseBatch.count < SPWebsocketIndexBatchSize || self.responseBatch.count % SPWebsocketIndexBatchSize == 0) {
            [self processBatchForBucket:bucket];
		}
    }
}

- (void)handleOptions:(NSString *)options bucket:(SPBucket *)bucket {
	
    NSDictionary *optionsDict = [options sp_objectFromJSONString];
	
	bucket.localNamespace	= optionsDict[@"namespace"];
	bucket.exposeNamespace	= [optionsDict[@"expose_namespace"] boolValue];
}

- (void)allVersionsFinishedForBucket:(SPBucket *)bucket {
    [self processBatchForBucket:bucket];
    [self resetRetryDelay];

    SPLogVerbose(@"Simperium finished processing all objects from index (%@)", self.name);

    // Save it now that all versions are fetched; it improves performance to wait until this point
    //[simperium saveWithoutSyncing];

    if ([self.versionsWithErrors count] > 0) {
        // Try the index refresh again; this could be more efficient since we could know which version requests
        // failed, but it should happen rarely so take the easy approach for now
        SPLogWarn(@"Index refresh complete (%@) but %lu versions didn't load, retrying...", self.name, (unsigned long)[self.versionsWithErrors count]);

        // Create an array in the expected format
        NSMutableArray *errorArray = [NSMutableArray arrayWithCapacity: [self.versionsWithErrors count]];
        for (NSString *key in [self.versionsWithErrors allKeys]) {
            id errorVersion = [self.versionsWithErrors objectForKey:key];
            NSDictionary *versionDict = @{ @"v" : errorVersion,
										   @"id" : key};
            [errorArray addObject:versionDict];
        }
		
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
			[self performSelector:@selector(requestVersionsForKeys:bucket:) withObject: errorArray withObject:bucket];
		});

        return;
    }

    // All versions were received successfully, so update the lastChangeSignature
    [bucket setLastChangeSignature:self.pendingLastChangeSignature];
    self.pendingLastChangeSignature = nil;
    self.nextMark = nil;
    self.indexing = NO;

    // There could be some processing happening on the queue still, so don't start until they're done
    dispatch_async(bucket.processorQueue, ^{
        if (self.started) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([bucket.delegate respondsToSelector:@selector(bucketDidFinishIndexing:)]) {
                    [bucket.delegate bucketDidFinishIndexing:bucket];
				}

                [self startProcessingChangesForBucket:bucket];
            });
        }
    });
}

//- (void)getIndexFailed:(ASIHTTPRequest *)request
//{
//    gettingVersions = NO;
//    int retry = [self nextRetryDelay];
//    SPLogWarn(@"Simperium warning: couldn't get index, will retry in %d seconds (%@): %d - %@", retry, bucket.name, [request responseStatusCode], [request responseString]);
//    numTransfers--;
//    [[self class] updateNetworkActivityIndictator];
//
//    [self performSelector:@selector(requestLatestVersions) withObject:nil afterDelay:retry];
//}


#pragma mark Object Versions

- (void)requestVersions:(int)numVersions object:(id<SPDiffable>)object {
    // If already retrieving versions on this channel, don't do it again
    if (self.retrievingObjectHistory) {
        return;
	}
    
    NSInteger startVersion = [object.ghost.version integerValue];
    self.retrievingObjectHistory = YES;
    self.objectVersionsPending = MIN(startVersion, numVersions);
    
    for (NSInteger i=startVersion; i>=1 && i>=startVersion-_objectVersionsPending; i--) {
        NSString *versionStr = [NSString stringWithFormat:@"%ld", (long)i];
        NSString *message = [NSString stringWithFormat:@"%d:e:%@.%@", self.number, object.simperiumKey, versionStr];
        SPLogVerbose(@"Simperium sending object version request (%@): %@", self.name, message);
        [self.webSocketManager send:message];
    }
}


#pragma mark Sharing

- (void)shareObject:(id<SPDiffable>)object withEmail:(NSString *)email {
    // Not yet implemented with WebSockets
}


#pragma mark Static Helpers: 
#pragma mark MockWebSocketChannel relies on this mechanism to register itself, while running the Unit Testing target

static Class _class;

+ (void)load {
	_class = [SPWebSocketChannel class];
}

+ (void)registerClass:(Class)c {
	_class = c;
}

+ (instancetype)channelWithSimperium:(Simperium *)s clientID:(NSString *)clientID {
	return [[_class alloc] initWithSimperium:s clientID:clientID];
}

@end
