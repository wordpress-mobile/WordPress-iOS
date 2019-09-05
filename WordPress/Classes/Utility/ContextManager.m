#import "ContextManager.h"
#import "ContextManager-Internals.h"
#import "ALIterativeMigrator.h"
@import WordPressShared.WPAnalytics;

// MARK: - Static Variables
//
static ContextManager *_instance;
static ContextManager *_override;


// MARK: - Private Properties
//
@interface ContextManager ()

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSManagedObjectContext *writerContext;
@property (nonatomic, assign) BOOL migrationFailed;

@end


// MARK: - ContextManager
//
@implementation ContextManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self startListeningToMainContextNotifications];
    }

    return self;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[ContextManager alloc] init];
    });

    return _override ?: _instance;
}

+ (void)overrideSharedInstance:(ContextManager *)contextManager
{
    [ContextManager sharedInstance];
    _override = contextManager;
}


#pragma mark - Contexts

- (NSManagedObjectContext *const)newDerivedContext
{
    return [self newChildContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
}

- (NSManagedObjectContext *const)newMainContextChildContext
{
    return [self newChildContextWithConcurrencyType:NSMainQueueConcurrencyType];
}

- (NSManagedObjectContext *const)writerContext
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.persistentStoreCoordinator = self.persistentStoreCoordinator;
        self.writerContext = context;
    });

    return _writerContext;
}

- (NSManagedObjectContext *const)mainContext
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        context.parentContext = self.writerContext;
        self.mainContext = context;
    });

    return _mainContext;
}

- (NSManagedObjectContext *const)newChildContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc]
                                            initWithConcurrencyType:concurrencyType];
    childContext.parentContext = self.mainContext;
    childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;

    return childContext;
}


#pragma mark - Context Saving and Merging

- (void)saveDerivedContext:(NSManagedObjectContext *)context
{
    [self saveDerivedContext:context withCompletionBlock:nil];
}

- (void)saveDerivedContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock
{
    [context performBlock:^{
        NSError *error;
        if (![context obtainPermanentIDsForObjects:context.insertedObjects.allObjects error:&error]) {
            DDLogError(@"Error obtaining permanent object IDs for %@, %@", context.insertedObjects.allObjects, error);
        }

        if (![context save:&error]) {
            DDLogError(@"Fatal Core Data Error encountered — throwing an exception. Underlying error is:\n %@", error);
            @throw [NSException exceptionWithName:@"Unresolved Core Data save error"
                                           reason:[NSString stringWithFormat:@"Unresolved Core Data save error - derived context. Core Data Error Domain: %@, code: %i", error.domain, error.code]
                                         userInfo:error.userInfo];
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

- (void)saveContextAndWait:(NSManagedObjectContext *)context
{
    if (context != self.mainContext) {
        [context performBlockAndWait:^{
            NSError *error = nil;
            
            if ([context hasChanges] && ![context save:&error]) {
                DDLogError(@"Fatal Core Data Error encountered — throwing an exception. Underlying error is:\n %@", error);
                @throw [NSException exceptionWithName:@"Unresolved Core Data save error"
                                               reason:[NSString stringWithFormat:@"Unresolved Core Data save error - derived context. Core Data Error Domain: %@, code: %i", error.domain, error.code]
                                             userInfo:error.userInfo];
            }
        }];
        
        if (context.parentContext != nil) {
            // It's not ideal for a context to be the one to define when its parent is saved, but in order
            // to follow the existing architecture, we can at least ensure saving the parent is safe, and
            // that we're not deadlocking the current thread to do that.
            //
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self saveContext:context.parentContext];
            });
        }
    } else {
        [context performBlockAndWait:^{
            [self internalSaveContext:context];
        }];
    }
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    [self saveContext:context withCompletionBlock:nil];
}

- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock
{
    // Save derived contexts a little differently
    // TODO - When the service refactor is complete, remove this - calling methods to Services should know
    //        what kind of context it is and call the saveDerivedContext at the end of the work
    if (context.parentContext == self.mainContext) {
        [self saveDerivedContext:context withCompletionBlock:completionBlock];
        return;
    }

    [context performBlock:^{
        [self internalSaveContext:context];
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), completionBlock);
        }
    }];
}

- (BOOL)obtainPermanentIDForObject:(NSManagedObject *)managedObject
{
    // Failsafe
    if (!managedObject) {
        return NO;
    }

    if (managedObject && ![managedObject.objectID isTemporaryID]) {
        // Object already has a permanent ID so just return success.
        return YES;
    }

    NSError *error;
    if (![managedObject.managedObjectContext obtainPermanentIDsForObjects:@[managedObject] error:&error]) {
        DDLogError(@"Error obtaining permanent object ID for %@, %@", managedObject, error);
        return NO;
    }
    return YES;
}

- (void)mergeChanges:(NSManagedObjectContext *)context fromContextDidSaveNotification:(NSNotification *)notification
{
    [context performBlock:^{
        // Fault-in updated objects before a merge to avoid any internal inconsistency errors later.
        // Based on old solution referenced here: http://www.mlsite.net/blog/?p=518
        NSSet* updates = [notification.userInfo objectForKey:NSUpdatedObjectsKey];
        for (NSManagedObject *object in updates) {
            NSManagedObject *objectInContext = [context existingObjectWithID:object.objectID error:nil];
            if ([objectInContext isFault]) {
                // Force a fault-in of the object's key-values
                [objectInContext willAccessValueForKey:nil];
            }
        }
        // Continue with the merge
        [context mergeChangesFromContextDidSaveNotification:notification];
    }];
}

- (BOOL)didMigrationFail
{
    return _migrationFailed;
}


#pragma mark - Setup

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    NSString *modelPath = [self modelPath];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    [self migrateDataModelsIfNecessary];

    // Attempt to open the store
    _migrationFailed = NO;
    
    NSURL *storeURL = self.storeURL;

    // This is important for automatic version migration. Leave it here!
    NSDictionary *options = @{
        NSInferMappingModelAutomaticallyOption            : @(YES),
        NSMigratePersistentStoresAutomaticallyOption    : @(YES)
    };

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                   initWithManagedObjectModel:[self managedObjectModel]];

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
        DDLogError(@"Error opening the database. %@\nDeleting the file and trying again", error);

        _migrationFailed = YES;
        
        // make a backup of the old database
        [[NSFileManager defaultManager] copyItemAtPath:storeURL.path
                                                toPath:[storeURL.path stringByAppendingString:@"~"]
                                                 error:&error];

        // delete the sqlite file and try again
        [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:nil];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil
                                                                 URL:storeURL
                                                             options:nil
                                                               error:&error]) {
            DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }

    return _persistentStoreCoordinator;
}


#pragma mark - Notification Helpers

- (void)startListeningToMainContextNotifications
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(mainContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.mainContext];
}

- (void)mainContextDidSave:(NSNotification *)notification
{
    // Defer I/O to a BG Writer Context. Simperium 4ever!
    //
    [self.writerContext performBlock:^{
        [self internalSaveContext:self.writerContext];
    }];
}


#pragma mark - Private Helpers

- (void)internalSaveContext:(NSManagedObjectContext *)context
{
    NSParameterAssert(context);
    
    NSError *error;
    if (![context obtainPermanentIDsForObjects:context.insertedObjects.allObjects error:&error]) {
        DDLogError(@"Error obtaining permanent object IDs for %@, %@", context.insertedObjects.allObjects, error);
    }
    
    if ([context hasChanges] && ![context save:&error]) {
        DDLogError(@"Unresolved core data error\n%@:", error);

        // error handling based on https://stackoverflow.com/a/3510918
        NSArray *errors = nil;
        NSString *errorName = nil;
        NSString *reasons = @"Reasons: ";
        if ([error code] == NSValidationMultipleErrorsError) {
            errors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
        } else {
            errors = [NSArray arrayWithObject:error];
        }

        if (errors && [errors count] > 0) {
            for (NSError * error in errors) {
                NSString *entityName = [[[[error userInfo] objectForKey:@"NSValidationErrorObject"] entity] name];
                NSString *attributeName = [[error userInfo] objectForKey:@"NSValidationErrorKey"];
                NSString *msg;
                switch ([error code]) {
                        // MARK: general errors
                    case NSCoreDataError:
                        msg = @"General Core Data error";
                        break;
                    case NSSQLiteError:
                        msg = @"General SQLite error";
                        break;
                    case NSInferredMappingModelError:
                        msg = @"Inferred mapping model creation error";
                        break;
                    case NSExternalRecordImportError:
                        msg = @"General error encountered while importing external records";
                        break;
                    case NSPersistentHistoryTokenExpiredError:
                        msg = @"The history token passed to NSPersistentChangeRequest was invalid";
                        break;

                        // MARK: managed object errors
                    case NSManagedObjectValidationError:
                        // Note: there are several specific validation errors not handled here since we don't use much (or any) CD validation
                        msg = @"Generic validation error.";
                        break;
                    case NSManagedObjectContextLockingError:
                        msg = @"Couldn't acquire a lock in a managed object context";
                        break;
                    case NSPersistentStoreCoordinatorLockingError:
                        msg = @"Couldn't acquire a lock in a persistent store coordinator";
                        break;
                    case NSManagedObjectReferentialIntegrityError:
                        msg = @"Attempt to fire a fault pointing to an object that does not exist: %@";
                        break;
                    case NSManagedObjectExternalRelationshipError:
                        msg = @"An object being saved has a relationship containing an object from another store";
                        break;
                    case NSManagedObjectMergeError:
                        msg = @"Unable to complete merging";
                        break;
                    case NSManagedObjectConstraintMergeError:
                        msg = @"Unable to complete merging due to multiple conflicting constraint violations";
                        break;

                        // MARK: persistent store errors
                    case NSPersistentStoreInvalidTypeError:
                        msg = @"Unknown persistent store type/format/version";
                        break;
                    case NSPersistentStoreTypeMismatchError:
                        msg = @"Store was accessed that does not match the specified type";
                        break;
                    case NSPersistentStoreIncompatibleSchemaError:
                        msg = @"Store returned an error for save operation";
                        break;
                    case NSPersistentStoreSaveError:
                        msg = @"Unclassified save error";
                        break;
                    case NSPersistentStoreIncompleteSaveError:
                        msg = @"One or more of the stores returned an error during save";
                        break;
                    case NSPersistentStoreSaveConflictsError:
                        attributeName = [[error userInfo] objectForKey:@"NSPersistentStoreSaveConflictsErrorKey"];
                        msg = [NSString stringWithFormat:@"An unresolved merge conflict was encountered on '%@'", attributeName];
                        break;
                    case NSPersistentStoreOperationError:
                        msg = @"The persistent store operation failed";
                        break;
                    case NSPersistentStoreOpenError:
                        msg = @"An error occurred while attempting to open the persistent store";
                        break;
                    case NSPersistentStoreTimeoutError:
                        msg = @"Failed to connect to the persistent store within the specified timeout";
                        break;
                    case NSPersistentStoreUnsupportedRequestTypeError:
                        msg = @"An NSPersistentStore subclass was passed an NSPersistentStoreRequest that it did not understand";
                        break;
                    case NSPersistentStoreIncompatibleVersionHashError:
                        msg = @"Entity version hashes incompatible with data model";
                        break;

                        // MARK: migration errors
                    case NSMigrationError:
                        msg = @"General migration error";
                        break;
                    case NSMigrationConstraintViolationError:
                        msg = @"Migration failed due to a violated uniqueness constraint";
                        break;
                    case NSMigrationCancelledError:
                        msg = @"Migration failed due to manual cancellation";
                        break;
                    case NSMigrationMissingSourceModelError:
                        msg = @"Migration failed due to missing source data model";
                        break;
                    case NSMigrationMissingMappingModelError:
                        msg = @"Migration failed due to missing mapping model";
                        break;
                    case NSMigrationManagerSourceStoreError:
                        msg = @"Migration failed due to a problem with the source data store";
                        break;
                    case NSMigrationManagerDestinationStoreError:
                        msg = @"Migration failed due to a problem with the destination data store";
                        break;
                    case NSEntityMigrationPolicyError:
                        msg = @"Migration failed during processing of the entity migration policy";
                        break;

                    default:
                        msg = [NSString stringWithFormat:@"Unknown error (code %i).", [error code]];
                        break;
                }

                if (errorName == nil) {
                    errorName = [NSString stringWithFormat:@"Unresolved Core Data save error: %@", msg];
                    reasons = [reasons stringByAppendingFormat:@"%@\n", (entityName? : @"no entity name provided")];
                } else {
                    reasons = [reasons stringByAppendingFormat:@"%@%@%@\n", (entityName?:@""),(entityName?@": ":@""),msg];
                }
            }
        }

        @throw [NSException exceptionWithName:errorName
                                       reason:reasons
                                     userInfo:error.userInfo];
    }
}

- (void)migrateDataModelsIfNecessary
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[self storeURL] path]]) {
        DDLogInfo(@"No store exists at URL %@.  Skipping migration.", [self storeURL]);
        return;
    }
    
    NSDictionary *metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                               URL:[self storeURL]
                                                           options:nil
                                                             error:nil];
    BOOL migrationNeeded = ![self.managedObjectModel isConfiguration:nil compatibleWithStoreMetadata:metadata];
    
    if (migrationNeeded) {
        DDLogWarn(@"Migration required for persistent store.");
        NSError *error = nil;
        NSArray *sortedModelNames = [self sortedModelNames];
        BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:[self storeURL]
                                                               ofType:NSSQLiteStoreType
                                                              toModel:self.managedObjectModel
                                                    orderedModelNames:sortedModelNames
                                                                error:&error];
        if (!migrateResult || error != nil) {
            DDLogError(@"Unable to migrate store: %@", error);
        }
    }
}

- (NSArray *)sortedModelNames
{
    NSString *modelPath = [self modelPath];
    NSString *versionPath = [modelPath stringByAppendingPathComponent:@"VersionInfo.plist"];
    NSDictionary *versionInfo = [NSDictionary dictionaryWithContentsOfFile:versionPath];
    NSArray *modelNames = [[versionInfo[@"NSManagedObjectModel_VersionHashes"] allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    
    return modelNames;
}

- (NSURL *)storeURL
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask,
                                                                        YES) lastObject];
    
    return [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"WordPress.sqlite"]];
}

- (NSString *)modelPath
{
    return [[NSBundle mainBundle] pathForResource:@"WordPress" ofType:@"momd"];
}

@end
