#import "ContextManager.h"
#import "ContextManager-Internals.h"
#import "WordPressComApi.h"
#import "ALIterativeMigrator.h"

static ContextManager *instance;

@interface ContextManager ()

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, assign) BOOL migrationFailed;

@end

@implementation ContextManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ContextManager alloc] init];
    });
    return instance;
}

+ (void)overrideSharedInstance:(ContextManager *)contextManager
{
    [ContextManager sharedInstance];
    instance = contextManager;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Contexts

- (NSManagedObjectContext *const)newDerivedContext
{
    NSManagedObjectContext *derived = [[NSManagedObjectContext alloc]
                                       initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    derived.parentContext = self.mainContext;
    derived.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;

    return derived;
}

- (NSManagedObjectContext *const)mainContext
{
    if (_mainContext) {
        return _mainContext;
    }
    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];

    return _mainContext;
}

#pragma mark - Context Saving and Merging

- (void)saveDerivedContext:(NSManagedObjectContext *)context
{
    [self saveDerivedContext:context withCompletionBlock:nil];
}

- (void)saveDerivedContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)())completionBlock
{
    [context performBlock:^{
        NSError *error;
        if (![context obtainPermanentIDsForObjects:context.insertedObjects.allObjects error:&error]) {
            DDLogError(@"Error obtaining permanent object IDs for %@, %@", context.insertedObjects.allObjects, error);
        }

        if (![context save:&error]) {
            @throw [NSException exceptionWithName:@"Unresolved Core Data save error"
                                           reason:@"Unresolved Core Data save error - derived context"
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
    [context performBlockAndWait:^{
        [self internalSaveContext:context];
    }];
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    [self saveContext:context withCompletionBlock:nil];
}

- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)())completionBlock
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
        
        [WPAnalytics track:WPAnalyticsStatLogout];
    }

    return _persistentStoreCoordinator;
}


#pragma mark - Private Helpers

- (void)internalSaveContext:(NSManagedObjectContext *)context
{
    NSParameterAssert(context);
    
    NSError *error;
    if (![context obtainPermanentIDsForObjects:context.insertedObjects.allObjects error:&error]) {
        DDLogError(@"Error obtaining permanent object IDs for %@, %@", context.insertedObjects.allObjects, error);
    }
    
    if (![context save:&error]) {
        DDLogError(@"Unresolved core data error\n%@:", error);
        @throw [NSException exceptionWithName:@"Unresolved Core Data save error"
                                       reason:@"Unresolved Core Data save error"
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
