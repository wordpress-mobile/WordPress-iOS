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
#import "DDLog.h"

#define PATH_KEY @"SPPathKey"
#define PATH_BUCKET @"SPPathBucket"
#define PATH_ATTRIBUTE @"SPPathAttribute"

static int ddLogLevel = LOG_LEVEL_INFO;

@interface SPRelationshipResolver() {
    dispatch_queue_t queue;
}

@property (nonatomic, strong) NSMutableDictionary *pendingRelationships;
@property (nonatomic, strong) dispatch_queue_t queue;

@end


@implementation SPRelationshipResolver
@synthesize pendingRelationships;
@synthesize queue;

+ (int)ddLogLevel {
    return ddLogLevel;
}

+ (void)ddSetLogLevel:(int)logLevel {
    ddLogLevel = logLevel;
}

- (id)init {
    if ((self = [super init])) {
        self.pendingRelationships = [NSMutableDictionary dictionaryWithCapacity:10];
        NSString *queueLabel = [@"com.simperium." stringByAppendingString:[[self class] description]];
        queue = dispatch_queue_create([queueLabel cStringUsingEncoding:NSUTF8StringEncoding], NULL);
    }
    
    return self;
}


- (void)writePendingReferences:(id<SPStorageProvider>)storage {
    if ([pendingRelationships count] == 0) {
        // If there's already nothing there, save some CPU by not writing anything
        NSDictionary *metadata = [storage metadata];
        NSString *pendingKey = [NSString stringWithFormat:@"SPPendingReferences"];
        NSDictionary *pendingDict = [metadata objectForKey:pendingKey];
        if (!pendingDict)
            return;
    }
    
    NSMutableDictionary *metadata = [[storage metadata] mutableCopy];
    NSString *key = [NSString stringWithFormat:@"SPPendingReferences"];
	[metadata setObject:pendingRelationships forKey: key];
    [storage setMetadata:metadata];
}

- (void)loadPendingRelationships:(id<SPStorageProvider>)storage {
    // Load changes that didn't get a chance to send
    NSString *pendingKey = [NSString stringWithFormat:@"SPPendingReferences"];
	NSDictionary *pendingDict = [[storage metadata] objectForKey:pendingKey];
    for (NSString *key in [pendingDict allKeys]) {
        // Manually create mutable children
        NSArray *loadPaths = [pendingDict objectForKey:key];
        NSMutableArray *paths = [NSMutableArray arrayWithArray:loadPaths];
        [pendingRelationships setValue:paths forKey:key];
    }
}


- (BOOL)hasPendingReferenceToKey:(NSString *)key {
    return [pendingRelationships objectForKey:key] != nil;
}

- (void)addPendingRelationshipToKey:(NSString *)key fromKey:(NSString *)fromKey bucketName:(NSString *)bucketName
                   attributeName:(NSString *)attributeName storage:(id<SPStorageProvider>)storage {
    if (key.length == 0) {
        DDLogWarn(@"Simperium warning: received empty pending reference to attribute %@", attributeName);
        return;
    }
    
    NSMutableDictionary *path = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 fromKey, PATH_KEY,
                                 bucketName, PATH_BUCKET,
                                 attributeName, PATH_ATTRIBUTE, nil];
    DDLogVerbose(@"Simperium adding pending reference from %@ (%@) to %@ (%@)", fromKey, attributeName, key, bucketName);
    
    // Check to see if any references are already being tracked for this entity
    NSMutableArray *paths = [pendingRelationships objectForKey: key];
    if (paths == nil) {
        paths = [NSMutableArray arrayWithCapacity:3];
        [pendingRelationships setObject: paths forKey: key];
    }
    [paths addObject:path];
    [self writePendingReferences:storage];
}

- (void)resolvePendingRelationshipsToKey:(NSString *)toKey bucketName:(NSString *)bucketName storage:(id<SPStorageProvider>)storage {
    // The passed entity is now synced, so check for any pending references to it that can now be resolved
    NSMutableArray *paths = [pendingRelationships objectForKey: toKey];
    if (paths != nil) {
        
    // The following code could batch fault all the objects that will be touched, but is probably overkill
/*
        // Construct lists of keys from the paths for batch faulting
        NSMutableDictionary *batchDict = [NSMutableDictionary dictionaryWithCapacity:3];
        for (NSDictionary *path in paths) {
            NSString *fromKey = [path objectForKey:PATH_KEY];
            NSString *fromBucketName = [path objectForKey:PATH_BUCKET];

            NSMutableArray *keyList = [batchDict objectForKey:fromBucketName];
            if (keyList == nil) {
                keyList = [NSMutableArray arrayWithCapacity:3];
                [batchDict setObject:keyList forKey: fromBucketName];
            }
            [keyList addObject:fromKey];
        }
        
        // Do the faulting for each bucket
        NSMutableDictionary *faultedObjects = [NSMutableDictionary dictionaryWithCapacity:[paths count]];
        for (NSString *key in [batchDict allKeys]) {
            NSDictionary *fromObjects = [threadSafeStorage faultObjectsForKeys:[batchDict objectForKey:key] bucketName:key];
            [faultedObjects addEntriesFromDictionary:fromObjects];
        }
*/
        // Resolve the references but do it in the background
        dispatch_async(queue, ^{
            id<SPStorageProvider> threadSafeStorage = [storage threadSafeStorage];
			[threadSafeStorage beginSafeSection];
			
            id<SPDiffable>toObject = [threadSafeStorage objectForKey:toKey bucketName:bucketName];
            
            if (!toObject) {
                DDLogError(@"Simperium error, tried to resolve reference to an object that doesn't exist yet (%@): %@", bucketName, toKey);
				[threadSafeStorage finishSafeSection];
                return;
            }

            for (NSDictionary *path in paths) {
                // There'd be no way to get the entityName here since there's no way to look at an instance's members
                // Get it from the "path" instead
                NSString *fromKey = [path objectForKey:PATH_KEY];
                NSString *fromBucketName = [path objectForKey:PATH_BUCKET];
                NSString *attributeName = [path objectForKey:PATH_ATTRIBUTE];
                id<SPDiffable> fromObject = [threadSafeStorage objectForKey:fromKey bucketName:fromBucketName];
                DDLogVerbose(@"Simperium resolving pending reference for %@.%@=%@", fromKey, attributeName, toKey);
                [fromObject simperiumSetValue:toObject forKey: attributeName];
                
                // Get the key reference into the ghost as well
                [fromObject.ghost.memberData setObject:toKey forKey: attributeName];
                fromObject.ghost.needsSave = YES;
            }
			
            [threadSafeStorage save];
			[threadSafeStorage finishSafeSection];
			
            dispatch_async(dispatch_get_main_queue(), ^{
                // All references to entity were resolved above, so remove it from the pending array
                [pendingRelationships removeObjectForKey:toKey];
                [self writePendingReferences:storage];
                
                // Expect the context to be saved elsewhere
                //[storage save];
            });
        });
    }
}

- (void)reset:(id<SPStorageProvider>)storage {
    [self.pendingRelationships removeAllObjects];
    [self writePendingReferences:storage];
    [storage save];
}

@end
