#import "ContextManager.h"
#import "WordPressComApi.h"

static ContextManager *instance;

@interface ContextManager ()

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSManagedObjectContext *rootContext;

@end

@implementation ContextManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ContextManager alloc] init];
    });
    return instance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Contexts

- (NSManagedObjectContext *const)newDerivedContext {
    NSManagedObjectContext *derived = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    derived.parentContext = self.mainContext;
    derived.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;

    return derived;
}

- (NSManagedObjectContext *const)mainContext {
    if (_mainContext) {
        return _mainContext;
    }
    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainContext.parentContext = self.rootContext;
    _mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveChangesInRootContext:) name:NSManagedObjectContextDidSaveNotification object:_mainContext];
    return _mainContext;
}

- (NSManagedObjectContext *const)rootContext {
    if (_rootContext) {
        return _rootContext;
    }
    _rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _rootContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    _rootContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;

    return _rootContext;
}

- (void)saveChangesInRootContext:(NSNotification *)notification {
    [self.rootContext performBlock:^{
        DDLogVerbose(@"Saving changes in root context");
        [self.rootContext processPendingChanges];
        
        // Changes are not saved out to the persistent store coordinator until the root context is saved
        [self saveContext:self.rootContext];
    }];
}

#pragma mark - Context Saving and Merging

- (void)saveDerivedContext:(NSManagedObjectContext *)context {
    [self saveDerivedContext:context withCompletionBlock:nil];
}

- (void)saveDerivedContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)())completionBlock {
    [context performBlock:^{
        NSError *error;
        if (![context obtainPermanentIDsForObjects:context.insertedObjects.allObjects error:&error]) {
            DDLogError(@"Error obtaining permanent object IDs for %@, %@", context.insertedObjects.allObjects, error);
        }
        
        if (![context save:&error]) {
            @throw [NSException exceptionWithName:@"Unresolved Core Data save error"
                                           reason:@"Unresolved Core Data save error - derived context"
                                         userInfo:[error userInfo]];
        }
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), completionBlock);
        }
        
        // While this is needed because we don't observe change notifications for the derived context, it
        // breaks concurrency rules for Core Data.  Provide a mechanism to destroy a derived context that
        // unregisters it from the save notification instead and rely upon that for merging.
        [self saveContext:self.mainContext];
    }];
}

- (void)saveContext:(NSManagedObjectContext *)context {
    // Save derived contexts a little differently
    // TODO - When the service refactor is complete, remove this - calling methods to Services should know what kind of context
    //        it is and call the saveDerivedContext at the end of the work
    if (context.parentContext == self.mainContext) {
        [self saveDerivedContext:context];
        return;
    }
    
    [context performBlock:^{
        NSError *error;
        if (![context obtainPermanentIDsForObjects:context.insertedObjects.allObjects error:&error]) {
            DDLogError(@"Error obtaining permanent object IDs for %@, %@", context.insertedObjects.allObjects, error);
        }
        
        if (![context save:&error]) {
            DDLogError(@"Unresolved core data error\n%@:", error);
            @throw [NSException exceptionWithName:@"Unresolved Core Data save error"
                                           reason:@"Unresolved Core Data save error"
                                         userInfo:[error userInfo]];
        }
    }];
}

#pragma mark - Setup

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"WordPress" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSURL *storeURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"WordPress.sqlite"]];
	
	// This is important for automatic version migration. Leave it here!
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, nil];
	
	NSError *error = nil;
	
    // The following conditional code is meant to test the detection of mapping model for migrations
    // It should remain disabled unless you are debugging why migrations aren't run
#if FALSE
	DDLogInfo(@"Debugging migration detection");
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
																							  URL:storeURL
																							error:&error];
	if (sourceMetadata == nil) {
		DDLogInfo(@"Can't find source persistent store");
	} else {
		DDLogInfo(@"Source store: %@", sourceMetadata);
	}
	NSManagedObjectModel *destinationModel = [self managedObjectModel];
	BOOL pscCompatibile = [destinationModel
						   isConfiguration:nil
						   compatibleWithStoreMetadata:sourceMetadata];
	if (pscCompatibile) {
		DDLogInfo(@"No migration needed");
	} else {
		DDLogInfo(@"Migration needed");
	}
	NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:sourceMetadata];
	if (sourceModel != nil) {
		DDLogInfo(@"source model found");
	} else {
		DDLogInfo(@"source model not found");
	}
    
	NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel
																 destinationModel:destinationModel];
	NSMappingModel *mappingModel = [NSMappingModel mappingModelFromBundles:[NSArray arrayWithObject:[NSBundle mainBundle]]
															forSourceModel:sourceModel
														  destinationModel:destinationModel];
	if (mappingModel != nil) {
		DDLogInfo(@"mapping model found");
	} else {
		DDLogInfo(@"mapping model not found");
	}
    
	if (NO) {
		BOOL migrates = [manager migrateStoreFromURL:storeURL
												type:NSSQLiteStoreType
											 options:nil
									withMappingModel:mappingModel
									toDestinationURL:storeURL
									 destinationType:NSSQLiteStoreType
								  destinationOptions:nil
											   error:&error];
        
		if (migrates) {
			DDLogInfo(@"migration went OK");
		} else {
			DDLogInfo(@"migration failed: %@", [error localizedDescription]);
		}
	}
	
	DDLogInfo(@"End of debugging migration detection");
#endif
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
		DDLogError(@"Error opening the database. %@\nDeleting the file and trying again", error);
#ifdef CORE_DATA_MIGRATION_DEBUG
		// Don't delete the database on debug builds
		// Makes migration debugging less of a pain
		abort();
#endif
        
        // make a backup of the old database
        [[NSFileManager defaultManager] copyItemAtPath:storeURL.path toPath:[storeURL.path stringByAppendingString:@"~"] error:&error];
        // delete the sqlite file and try again
		[[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:nil];
		if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
			DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
    }
    
    return _persistentStoreCoordinator;
}

@end
