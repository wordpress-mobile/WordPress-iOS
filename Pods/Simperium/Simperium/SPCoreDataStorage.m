//
//  SPCoreDataStorage.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-17.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPCoreDataStorage.h"
#import "SPManagedObject+Internals.h"
#import "NSString+Simperium.h"
#import "SPCoreDataExporter.h"
#import "SPSchema.h"
#import "SPThreadsafeMutableSet.h"
#import "SPLogger.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

NSString* const SPCoreDataBucketListKey = @"SPCoreDataBucketListKey";
NSString* const SPCoreDataWorkerContext	= @"SPCoreDataWorkerContext";
static SPLogLevels logLevel				= SPLogLevelsInfo;
static NSInteger const SPWorkersDone	= 0;


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPCoreDataStorage ()
@property (nonatomic, strong, readwrite) NSManagedObjectContext			*writerManagedObjectContext;
@property (nonatomic, strong, readwrite) NSManagedObjectContext			*mainManagedObjectContext;
@property (nonatomic, strong, readwrite) NSManagedObjectModel			*managedObjectModel;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator	*persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) NSMutableDictionary			*classMappings;
@property (nonatomic, strong, readwrite) SPThreadsafeMutableSet			*remotelyDeletedKeys;
@property (nonatomic, weak,   readwrite) SPCoreDataStorage				*sibling;
@property (nonatomic, strong, readwrite) NSConditionLock				*mutex;
- (void)addObserversForMainContext:(NSManagedObjectContext *)context;
- (void)addObserversForChildrenContext:(NSManagedObjectContext *)context;
@end


#pragma mark ====================================================================================
#pragma mark SPCoreDataStorage
#pragma mark ====================================================================================

@implementation SPCoreDataStorage

- (id)initWithModel:(NSManagedObjectModel *)model mainContext:(NSManagedObjectContext *)mainContext coordinator:(NSPersistentStoreCoordinator *)coordinator {
    if (self = [super init]) {
		// Create a writer MOC
		self.writerManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		
        stashedObjects = [NSMutableSet setWithCapacity:3];
        self.classMappings = [NSMutableDictionary dictionary];
		self.remotelyDeletedKeys = [SPThreadsafeMutableSet set];
		
        self.persistentStoreCoordinator = coordinator;
        self.managedObjectModel = model;
        self.mainManagedObjectContext = mainContext;
		
        [self.mainManagedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
		
		// Just one mutex for this Simperium stack
		self.mutex = [[NSConditionLock alloc] initWithCondition:SPWorkersDone];
		
		// The new writer MOC will be the only one with direct access to the persistentStoreCoordinator
		self.writerManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
		self.mainManagedObjectContext.parentContext = self.writerManagedObjectContext;

        [self addObserversForMainContext:self.mainManagedObjectContext];
    }
    return self;
}

- (id)initWithSibling:(SPCoreDataStorage *)aSibling {
    if (self = [super init]) {
        self.sibling = aSibling;
		
        // Create an ephemeral, thread-safe context that will push its changes directly to the writer MOC,
		// and will also post the changes to the MainQueue
        self.mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
		self.mainManagedObjectContext.userInfo[SPCoreDataWorkerContext] = @(true);
		
		self.writerManagedObjectContext = aSibling.writerManagedObjectContext;
		
		// Wire the Thread Confined Context, directly to the writer MOC
		self.mainManagedObjectContext.parentContext = self.writerManagedObjectContext;
		
        // Simperium's context always trumps the app's local context (potentially stomping in-memory changes)
        [self.mainManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        
        // For efficiency
        [self.mainManagedObjectContext setUndoManager:nil];
        
		// Shared mutex
		self.mutex = aSibling.mutex;
		
        // An observer is expected to handle merges for otherContext when the threaded context is saved
		[self addObserversForChildrenContext:self.mainManagedObjectContext];
    }
    
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setBucketList:(NSDictionary *)dict {
    // Set a custom field on the context so that objects can figure out their own buckets when they wake up
	NSMutableDictionary* bucketList = self.writerManagedObjectContext.userInfo[SPCoreDataBucketListKey];
	
	if (!bucketList) {
		bucketList = [NSMutableDictionary dictionary];
		[self.writerManagedObjectContext.userInfo setObject:bucketList forKey:SPCoreDataBucketListKey];
	}
	
	[bucketList addEntriesFromDictionary:dict];
}

- (NSArray *)exportSchemas {
    SPCoreDataExporter *exporter = [[SPCoreDataExporter alloc] init];
    NSDictionary *definitionDict = [exporter exportModel:self.managedObjectModel classMappings:self.classMappings];
    
    SPLogInfo(@"Simperium loaded %lu entity definitions", (unsigned long)[definitionDict count]);
    
    NSUInteger numEntities = [[definitionDict allKeys] count];
    NSMutableArray *schemas = [NSMutableArray arrayWithCapacity:numEntities];
    for (NSString *entityName in [definitionDict allKeys]) {
        NSDictionary *entityDict = [definitionDict valueForKey:entityName];
        
        SPSchema *schema = [[SPSchema alloc] initWithBucketName:entityName data:entityDict];
        [schemas addObject:schema];
    }
    return schemas;
}

- (id<SPStorageProvider>)threadSafeStorage {
    return [[SPCoreDataStorage alloc] initWithSibling:self];
}

- (id<SPDiffable>)objectForKey:(NSString *)key bucketName:(NSString *)bucketName {
	
    NSEntityDescription *entityDescription	= [NSEntityDescription entityForName:bucketName inManagedObjectContext:self.mainManagedObjectContext];
    NSPredicate *predicate					= [NSPredicate predicateWithFormat:@"simperiumKey == %@", key];
	
    NSFetchRequest *fetchRequest			= [[NSFetchRequest alloc] init];
    fetchRequest.entity						= entityDescription;
    fetchRequest.predicate					= predicate;
	fetchRequest.fetchLimit					= 1;
	
    NSError *error;
    NSArray *items = [self.mainManagedObjectContext executeFetchRequest:fetchRequest error:&error];

	return [items firstObject];
}

- (NSArray *)objectsForKeys:(NSSet *)keys bucketName:(NSString *)bucketName {
    return [[self faultObjectsForKeys:[keys allObjects] bucketName:bucketName] allValues];
}

- (NSArray *)objectsForBucketName:(NSString *)bucketName predicate:(NSPredicate *)predicate {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:bucketName inManagedObjectContext:self.mainManagedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setReturnsObjectsAsFaults:YES];
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
	
    NSError *error;
    NSArray *items = [self.mainManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    return items;
}

- (NSArray *)objectKeysAndIdsForBucketName:(NSString *)bucketName {
    NSEntityDescription *entity = [NSEntityDescription entityForName:bucketName inManagedObjectContext:self.mainManagedObjectContext];
    if (entity == nil) {
        //SPLogWarn(@"Simperium warning: couldn't find any instances for entity named %@", entityName);
        return nil;
    }
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    // Execute a targeted fetch to preserve faults so that only simperiumKeys are loaded in to memory
    // http://stackoverflow.com/questions/3956406/core-data-how-to-get-nsmanagedobjects-objectid-when-nsfetchrequest-returns-nsdi
    NSExpressionDescription* objectIdDesc = [NSExpressionDescription new];
    objectIdDesc.name = @"objectID";
    objectIdDesc.expression = [NSExpression expressionForEvaluatedObject];
    objectIdDesc.expressionResultType = NSObjectIDAttributeType;
    NSDictionary *properties = [entity propertiesByName];
    request.resultType = NSDictionaryResultType;
    request.propertiesToFetch = [NSArray arrayWithObjects:[properties objectForKey:@"simperiumKey"], objectIdDesc, nil];
    
    NSError *error = nil;
    NSArray *results = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    if (results == nil) {
        // Handle the error.
        NSAssert1(0, @"Simperium error: couldn't load array of entities (%@)", bucketName);
    }
    
    return results;
    
}

- (NSArray *)objectKeysForBucketName:(NSString *)bucketName {
    NSArray *results = [self objectKeysAndIdsForBucketName:bucketName];
    
    NSMutableArray *objectKeys = [NSMutableArray arrayWithCapacity:[results count]];
    for (NSDictionary *result in results) {
        NSString *key = [result objectForKey:@"simperiumKey"];
        [objectKeys addObject:key];
    }
    
    return objectKeys;
}

- (NSInteger)numObjectsForBucketName:(NSString *)bucketName predicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:bucketName inManagedObjectContext:self.mainManagedObjectContext]];
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities) 
    if (predicate) {
        [request setPredicate:predicate];
    }
	
    NSError *err;
    NSUInteger count = [self.mainManagedObjectContext countForFetchRequest:request error:&err];
    if (count == NSNotFound) {
        //Handle error
        return 0;
    }
    
    return count;
}

- (id)objectAtIndex:(NSUInteger)index bucketName:(NSString *)bucketName {
    // Not supported
    return nil;
}

- (void)insertObject:(id<SPDiffable>)object bucketName:(NSString *)bucketName {
    // Not supported
}

- (NSDictionary *)faultObjectsForKeys:(NSArray *)keys bucketName:(NSString *)bucketName {
    // Batch fault a bunch of objects for efficiency
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"simperiumKey IN %@", keys];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:bucketName inManagedObjectContext:self.mainManagedObjectContext];
    [fetchRequest setEntity:entityDescription];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    
    NSError *error;
    NSArray *objectArray = [self.mainManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableDictionary *objects = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
    for (SPManagedObject *object in objectArray) {
        [objects setObject:object forKey:object.simperiumKey];
    }
    return objects;
}

- (void)refaultObjects:(NSArray *)objects {
    for (SPManagedObject *object in objects) {
        [self.mainManagedObjectContext refreshObject:object mergeChanges:NO];
    }
}

- (id)insertNewObjectForBucketName:(NSString *)bucketName simperiumKey:(NSString *)key {
	// Every object has its persistent storage managed automatically
    SPManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:bucketName
															inManagedObjectContext:self.mainManagedObjectContext];
	
    object.simperiumKey = key ? key : [NSString sp_makeUUID];
    
    // Populate with member data if applicable
//	if (memberData)
//		[entity loadMemberData: memberData manager: self];
    
	return object;
}

- (void)deleteObject:(id<SPDiffable>)object {
    SPManagedObject *managedObject = (SPManagedObject *)object;
    [managedObject.managedObjectContext deleteObject:managedObject];
	
	// NOTE:
	// 'mergeChangesFromContextDidSaveNotification' calls 'deleteObject' in the receiver context. As a result,
	// remote deletions will be posted as local deletions. Let's prevent that!
	if (self.sibling) {
		[self.sibling.remotelyDeletedKeys addObject:managedObject.simperiumKey];
	}
}

- (void)deleteAllObjectsForBucketName:(NSString *)bucketName {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:bucketName inManagedObjectContext:self.mainManagedObjectContext];
    [fetchRequest setEntity:entity];
    
    // No need to fault everything
    [fetchRequest setIncludesPropertyValues:NO];
    
    NSError *error;
    NSArray *items = [self.mainManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *managedObject in items) {
        [self.mainManagedObjectContext deleteObject:managedObject];
    }
	
    if (![self.mainManagedObjectContext save:&error]) {
        NSLog(@"Simperium error deleting %@ - error:%@",bucketName,error);
    }
}

- (void)validateObjectsForBucketName:(NSString *)bucketName {
    NSArray *results = [self objectKeysAndIdsForBucketName:bucketName];
    
    // Check each entity instance
    for (NSDictionary *result in results) {
        SPManagedObject *object = (SPManagedObject *)[self.mainManagedObjectContext objectWithID:result[@"objectID"]];
        NSString *key = [result objectForKey:@"simperiumKey"];
        // In apps like Simplenote where legacy data might exist on the device, the simperiumKey might need to
        // be set manually. Provide that opportunity here.
        if (key == nil) {
            if ([object respondsToSelector:@selector(getSimperiumKeyFromLegacyKey)]) {
                key = [object performSelector:@selector(getSimperiumKeyFromLegacyKey)];
                if (key && key.length > 0)
                    SPLogVerbose(@"Simperium local entity found without key (%@), porting legacy key: %@", bucketName, key);
            }
            
            // If it's still nil (unsynced local change in legacy system), treat it like a newly inserted object:
            // generate a UUID and mark it for sycing
            if (key == nil || key.length == 0) {
                SPLogVerbose(@"Simperium local entity found with no legacy key (created offline?); generating one now");
                key = [NSString sp_makeUUID];
            }
            object.simperiumKey = key;
            
            // The object is now managed by Simperium, so create a new ghost for it and be sure to configure its definition
            // (it's likely a legacy object that was fetched before Simperium was started)
            [self configureNewGhost:object];
            
            // The following is no longer needed; configureBucket is called in the object's awakeFromFetch as a result of
            // the object.simperiumKey assignment above
            // HOWEVER, when seeding/migrating data, the object could already have been faulted
            [object performSelector:@selector(configureBucket)];
        }
    }
    
    NSLog(@"Simperium managing %lu %@ object instances", (unsigned long)[results count], bucketName);
}

- (BOOL)save {
    // Standard way to save an NSManagedObjectContext
    NSError *error = nil;
    if (self.mainManagedObjectContext != nil) {
        @try {
            BOOL bChanged = [self.mainManagedObjectContext hasChanges];
            if (bChanged && ![self.mainManagedObjectContext save:&error]) {
                NSLog(@"Critical Simperium error while saving context: %@, %@", error, [error userInfo]);
                return NO;
            }
        } @catch (NSException *exception) {
            NSLog(@"Simperium exception while saving context: %@", (id)[exception userInfo] ?: (id)[exception reason]);	
        }
    }  
    return YES;
}

- (void)setMetadata:(NSDictionary *)metadata {
    NSPersistentStore *store = [self.persistentStoreCoordinator.persistentStores objectAtIndex:0];
    [self.persistentStoreCoordinator setMetadata:metadata forPersistentStore:store];
}

- (NSDictionary *)metadata {
    NSPersistentStore *store = [self.persistentStoreCoordinator.persistentStores objectAtIndex:0];
    return [store metadata];
}


// CD specific
# pragma mark Stashing and unstashing entities
- (NSArray *)allUpdatedAndInsertedObjects {
    NSMutableSet *unsavedEntities = [NSMutableSet setWithCapacity:3];
    
    // Add updated objects
    [unsavedEntities addObjectsFromArray:[[self.mainManagedObjectContext updatedObjects] allObjects]];
    
    // Also check for newly inserted objects
    [unsavedEntities addObjectsFromArray:[[self.mainManagedObjectContext insertedObjects] allObjects]];
    
    return [unsavedEntities allObjects];
}

- (void)stashUnsavedObjects {
    NSArray *entitiesToStash = [self allUpdatedAndInsertedObjects];
    
    if ([entitiesToStash count] > 0) {
        SPLogVerbose(@"Simperium stashing changes for %lu entities", (unsigned long)[entitiesToStash count]);
        [stashedObjects addObjectsFromArray: entitiesToStash];
    }
}


# pragma mark Main MOC + Children MOC Notification Handlers

- (void)managedContextWillSave:(NSNotification*)notification {
	NSManagedObjectContext *context	= (NSManagedObjectContext *)notification.object;
	NSMutableSet *temporaryObjects = [NSMutableSet set];
	
	for (NSManagedObject *mo in context.insertedObjects) {
		if (mo.objectID.isTemporaryID) {
			[temporaryObjects addObject:mo];
		}
	}
	
	if (temporaryObjects.count == 0) {
		return;
	}
	
	// Obtain permanentID's for newly inserted objects
	NSError *error = nil;
	if (![context obtainPermanentIDsForObjects:temporaryObjects.allObjects error:&error]) {
        SPLogVerbose(@"Unable to obtain permanent IDs for objects newly inserted into the main context: %@", error);
    }
}


# pragma mark Main MOC Notification Handlers

- (void)mainContextDidSave:(NSNotification *)notification {
	// Now that the changes have been pushed to the writerMOC, persist to disk
	[self saveWriterContext];
	
    // This bypass allows saving to be performed without triggering a sync, as is needed
    // when storing changes that come off the wire
    if (![self.delegate objectsShouldSync]) {
        return;
	}
	
	// Filter remotely deleted objects
	NSDictionary *userInfo	= notification.userInfo;
	NSMutableSet *locallyDeleted = [NSMutableSet set];
	for (SPManagedObject* mainMO in userInfo[NSDeletedObjectsKey]) {
		if ([mainMO isKindOfClass:[SPManagedObject class]] == NO) {
			continue;
		}
		if ([self.remotelyDeletedKeys containsObject:mainMO.simperiumKey] == NO) {
			// We'll need to post it
			[locallyDeleted addObject:mainMO];
		} else {
			// Cleanup!
			[self.remotelyDeletedKeys removeObject:mainMO.simperiumKey];
		}
	}
	
    // Sync all changes
    [self.delegate storage:self updatedObjects:userInfo[NSUpdatedObjectsKey] insertedObjects:userInfo[NSInsertedObjectsKey] deletedObjects:locallyDeleted];
}

- (void)mainContextObjectsDidChange:(NSNotification *)notification {
    // Check for inserted objects and init them
    NSSet *insertedObjects = [notification.userInfo objectForKey:NSInsertedObjectsKey];

    for (NSManagedObject *insertedObject in insertedObjects) {
        if ([insertedObject isKindOfClass:[SPManagedObject class]]) {
            SPManagedObject *object = (SPManagedObject *)insertedObject;
            [self configureInsertedObject: object];
        }
    }
}

- (void)addObserversForMainContext:(NSManagedObjectContext *)moc {
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(managedContextWillSave:) name:NSManagedObjectContextWillSaveNotification object:moc];
    [nc addObserver:self selector:@selector(mainContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:moc];
    [nc addObserver:self selector:@selector(mainContextObjectsDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:moc];
}


# pragma mark Children MOC Notification Handlers

- (void)childrenContextDidSave:(NSNotification*)notification {
	// Move the changes to the main MOC. This will NOT trigger main MOC's hasChanges flag.
	// NOTE: setting the mainMOC as the childrenMOC's parent will trigger 'mainMOC hasChanges' flag.
	// Which, in turn, can cause changes retrieved from the backend to get posted as local changes.
	NSManagedObjectContext* mainMOC = self.sibling.mainManagedObjectContext;
	[mainMOC performBlockAndWait:^{
		
		// Fault in all updated objects
		// (fixes NSFetchedResultsControllers that have predicates, see http://www.mlsite.net/blog/?p=518)		
        NSArray* updated = [notification.userInfo[NSUpdatedObjectsKey] allObjects];
		for (NSManagedObject* childMO in updated) {
			
			// Do not use 'objectWithId': might return an object that already got deleted
			NSManagedObject* localMO = [self.mainManagedObjectContext existingObjectWithID:childMO.objectID error:nil];
			if (localMO.isFault) {
				[localMO willAccessValueForKey:nil];
			}
        }
		
		// Proceed with the regular merge. This should trigger a contextDidChange note
		[mainMOC mergeChangesFromContextDidSaveNotification:notification];
		
		// Note: Once the changes have been merged to the mainMOC, let's persist to "disk"!
		[self saveWriterContext];
	}];
}

- (void)addObserversForChildrenContext:(NSManagedObjectContext *)context {
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(managedContextWillSave:) name:NSManagedObjectContextWillSaveNotification object:context];
    [nc addObserver:self selector:@selector(childrenContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:context];
}


# pragma mark Writer MOC Helpers

- (void)saveWriterContext {
	[self.writerManagedObjectContext performBlock:^{
        @try {
			NSError *error = nil;
            if ([self.writerManagedObjectContext hasChanges] && ![self.writerManagedObjectContext save:&error]) {
                NSLog(@"Critical Simperium error while persisting writer context's changes: %@, %@", error, error.userInfo);
            }
        } @catch (NSException *exception) {
            NSLog(@"Simperium exception while persisting writer context's changes: %@", exception.userInfo ? : exception.reason);
        }
	}];
}


#pragma mark - Synchronization

- (void)beginSafeSection {
	NSAssert([NSThread isMainThread] == false, @"It is not recommended to use this method on the main thread");

	[_mutex lock];
	NSInteger workers = _mutex.condition + 1;
	[_mutex unlockWithCondition:workers];
}

- (void)finishSafeSection {
	
	[_mutex lock];
	NSInteger workers = _mutex.condition - 1;
	[_mutex unlockWithCondition:workers];
}

- (void)beginCriticalSection {
	NSAssert([NSThread isMainThread] == false, @"It is not recommended to use this method on the main thread");

	[_mutex lockWhenCondition:SPWorkersDone];
}

- (void)finishCriticalSection {
	[_mutex unlock];
}


#pragma mark - Standard stack

+ (BOOL)isMigrationNecessary:(NSURL *)storeURL managedObjectModel:(NSManagedObjectModel *)managedObjectModel {
    NSError *error = nil;
    
    // Determine if a migration is needed
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                              URL:storeURL
                                                                                            error:&error];

    // A migration is needed if the existing model isn't compatible with the given model
    BOOL pscCompatibile = [managedObjectModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
    return !pscCompatibile;
}

+ (BOOL)newCoreDataStack:(NSString *)modelName mainContext:(NSManagedObjectContext **)mainContext model:(NSManagedObjectModel **)model coordinator:(NSPersistentStoreCoordinator **)coordinator {
    NSLog(@"Setting up Core Data: %@", modelName);
    //NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Simplenote" withExtension:@"momd"];
    
    NSURL *developerModelURL;
    @try {
        developerModelURL = [NSURL fileURLWithPath: [[NSBundle mainBundle]  pathForResource:modelName ofType:@"momd"]];
        *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:developerModelURL];
    } @catch (NSException *e) {
        NSLog(@"Simperium error: could not find the specified model file (%@.xcdatamodeld)", modelName);
        @throw; // rethrow the exception
    }
    
    // Setup the persistent store
    //NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Simplenote.sqlite"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *databaseFilename = [NSString stringWithFormat:@"%@.sqlite", bundleName];    
    NSString *path = [documentsDirectory stringByAppendingPathComponent:databaseFilename];
    NSURL *storeURL = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:*model];
    
    // Determine if lightweight migration is going to be necessary; this will be used to notify the app in case further action is needed
    BOOL lightweightMigrationNeeded = [SPCoreDataStorage isMigrationNecessary:storeURL managedObjectModel:*model];
    
    // Perform automatic, lightweight migration
    NSDictionary *options = @{
		NSMigratePersistentStoresAutomaticallyOption : @(YES),
		NSInferMappingModelAutomaticallyOption : @(YES)
	};
	
    if (![*coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
         //TODO: this can occur the first time you launch a Simperium app after adding Simperium to it. The existing data store lacks the dynamically added members, so it must be upgraded first, and then the opening of the persistent store must be attempted again.
         
        NSLog(@"Simperium failed to perform lightweight migration; app should perform manual migration");
    }    
    
    // Setup the context
    if (mainContext != nil)
    {
        *mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [*mainContext setUndoManager:nil];
    }
        
    return lightweightMigrationNeeded;
}

// Need to perform a manual migration in a particular case. Do this according to Apple's guidelines.
- (BOOL)migrateStore:(NSURL *)storeURL sourceModel:(NSManagedObjectModel *)srcModel destinationModel:(NSManagedObjectModel *)dstModel {
    NSError *error;
    NSMappingModel *mappingModel = [NSMappingModel inferredMappingModelForSourceModel:srcModel
                                                                     destinationModel:dstModel error:&error];
    if (error) {
        NSString *message = [NSString stringWithFormat:@"Inferring failed %@ [%@]",
                             [error description], ([error userInfo] ? [[error userInfo] description] : @"no user info")];
        NSLog(@"Migration failure message: %@", message);
        
        return NO;
    }
    
    NSValue *classValue = [[NSPersistentStoreCoordinator registeredStoreTypes] objectForKey:NSSQLiteStoreType];
    Class sqliteStoreClass = (Class)[classValue pointerValue];
    Class sqliteStoreMigrationManagerClass = [sqliteStoreClass migrationManagerClass];
    
    NSMigrationManager *manager = [[sqliteStoreMigrationManagerClass alloc]
                                   initWithSourceModel:srcModel destinationModel:dstModel];
    
    if (![manager migrateStoreFromURL:storeURL type:NSSQLiteStoreType
                              options:nil withMappingModel:mappingModel toDestinationURL:nil
                      destinationType:NSSQLiteStoreType destinationOptions:nil error:&error]) {
        
        NSString *message = [NSString stringWithFormat:@"Migration failed %@ [%@]",
                             [error description], ([error userInfo] ? [[error userInfo] description] : @"no user info")];
        NSLog(@"Migration failure message: %@", message);
        return NO;
    }
    return YES;
}

@end


// Unused code for dividing up changes per bucket (ugly)
//    // Divvy up according to buckets; this is necessary to avoid each object maintaining a reference back to its bucket, which doesn't
//    // work well with multiple Simperium instances
//    // On iOS5, bucket references on objects could work via userInfo on NSManagedObjectContext instead
//    NSMutableDictionary *bucketLists = [NSMutableDictionary dictionaryWithCapacity:5];
//
//    // This code is awful
//    for (id<SPDiffable>object in insertedObjects) {
//        NSString *bucketName = [self nameForEntityClass:[object class]];
//        NSMutableDictionary *objectLists = [bucketLists objectForKey:bucketName];
//        if (!objectLists) {
//            // Create a dict to hold all inserted, updated and deleted objects for that bucket
//            objectLists = [NSMutableDictionary dictionaryWithCapacity:3];
//            [bucketLists setObject:objectLists forKey:bucketName];
//        }
//        
//        NSMutableArray *bucketObjects = [objectLists objectForKey:@"insertedObjects"];
//        if (!bucketObjects) {
//            // Create an array in the dict
//            bucketObjects = [NSMutableArray arrayWithCapacity:3];
//            [objectLists setObject:bucketObjects forKey:@"insertedObjects"];
//        }
//        [bucketObjects addObject:object];
//    }
//
//    for (id<SPDiffable>object in updatedObjects) {
//        NSString *bucketName = [self nameForEntityClass:[object class]];
//        NSMutableDictionary *objectLists = [bucketLists objectForKey:bucketName];
//        if (!objectLists) {
//            // Create a dict to hold all inserted, updated and deleted objects for that bucket
//            objectLists = [NSMutableDictionary dictionaryWithCapacity:3];
//            [bucketLists setObject:objectLists forKey:bucketName];
//        }
//        
//        NSMutableArray *bucketObjects = [objectLists objectForKey:@"updatedObjects"];
//        if (!bucketObjects) {
//            // Create an array in the dict
//            bucketObjects = [NSMutableArray arrayWithCapacity:3];
//            [objectLists setObject:bucketObjects forKey:@"updatedObjects"];
//        }
//        [bucketObjects addObject:object];
//    }
//    
//    for (id<SPDiffable>object in deletedObjects) {
//        NSString *bucketName = [self nameForEntityClass:[object class]];
//        NSMutableDictionary *objectLists = [bucketLists objectForKey:bucketName];
//        if (!objectLists) {
//            // Create a dict to hold all inserted, updated and deleted objects for that bucket
//            objectLists = [NSMutableDictionary dictionaryWithCapacity:3];
//            [bucketLists setObject:objectLists forKey:bucketName];
//        }
//        
//        NSMutableArray *bucketObjects = [objectLists objectForKey:@"deletedObjects"];
//        if (!bucketObjects) {
//            // Create an array in the dict
//            bucketObjects = [NSMutableArray arrayWithCapacity:3];
//            [objectLists setObject:bucketObjects forKey:@"deletedObjects"];
//        }
//        [bucketObjects addObject:object];
//    }
