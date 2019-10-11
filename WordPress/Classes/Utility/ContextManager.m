#import "ContextManager.h"
#import "ContextManager-Internals.h"
#import "ALIterativeMigrator.h"
#import "WordPress-Swift.h"
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

- (void)saveContextAndWait:(NSManagedObjectContext *)context
{
    [self saveContext:context andWait:YES withCompletionBlock:nil];
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    [self saveContext:context andWait:NO withCompletionBlock:nil];
}

- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock
{
    [self saveContext:context andWait:NO withCompletionBlock:completionBlock];
}


- (void)saveContext:(NSManagedObjectContext *)context andWait:(BOOL)wait withCompletionBlock:(void (^)(void))completionBlock
{
    // Save derived contexts a little differently
    if (context.parentContext == self.mainContext) {
        [self saveDerivedContext:context andWait:wait withCompletionBlock:completionBlock];
        return;
    }

    if (wait) {
        [context performBlockAndWait:^{
            [self internalSaveContext:context withCompletionBlock:completionBlock];
        }];
    } else {
        [context performBlock:^{
            [self internalSaveContext:context withCompletionBlock:completionBlock];
        }];
    }
}

- (void)saveDerivedContext:(NSManagedObjectContext *)context andWait:(BOOL)wait withCompletionBlock:(void (^)(void))completionBlock
{
    if (wait) {
        [context performBlockAndWait:^{
            [self internalSaveContext:context];
            [self saveContext:self.mainContext andWait:wait withCompletionBlock:completionBlock];
        }];
    } else {
        [context performBlock:^{
            [self internalSaveContext:context];
            [self saveContext:self.mainContext andWait:wait withCompletionBlock:completionBlock];
        }];
    }
}

- (void)internalSaveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock
{
    [self internalSaveContext:context];

    if (completionBlock) {
        dispatch_async(dispatch_get_main_queue(), completionBlock);
    }
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
            @throw [NSException exceptionWithName:@"Can't initialize Core Data stack"
                                           reason:[error localizedDescription]
                                         userInfo:[error userInfo]];
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
        [self handleSaveError:error inContext:context];
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
