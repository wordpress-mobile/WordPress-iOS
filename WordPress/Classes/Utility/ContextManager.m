#import "ContextManager.h"
#import "WordPress-Swift.h"
@import WordPressShared.WPAnalytics;

#define SentryStartupEventAddError(event, error) [event addError:error file:__FILE__ function:__FUNCTION__ line:__LINE__]

// MARK: - Static Variables
//
static ContextManager *_instance;
static ContextManager *_override;


// MARK: - Private Properties
//
@interface ContextManager ()

@property (nonatomic, strong) NSPersistentStoreDescription *storeDescription;
@property (nonatomic, strong) NSPersistentContainer *persistentContainer;
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
        [NSValueTransformer registerCustomTransformers];
        [self startListeningToMainContextNotifications];
    }

    return self;
}

+ (instancetype)internalSharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[ContextManager alloc] init];
    });

    return _override ?: _instance;
}

#pragma mark - Contexts

- (NSManagedObjectContext *const)newDerivedContext
{
    return [self newChildContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
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
        [[[NullBlogPropertySanitizer alloc] initWithContext:context] sanitize];
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


#pragma mark - Setup

- (NSPersistentContainer *)persistentContainer
{
    if (_persistentContainer) {
        return _persistentContainer;
    }

    SentryStartupEvent *startupEvent = [SentryStartupEvent new];

    [self migrateDataModelsIfNecessary:startupEvent];

    NSURL *storeURL = self.storeURL;

    // Initialize the container
    NSPersistentContainer *persistentContainer = [[NSPersistentContainer alloc] initWithName:@"WordPress" managedObjectModel:self.managedObjectModel];
    persistentContainer.persistentStoreDescriptions = @[self.storeDescription];
    [persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *description, NSError *error) {
        if (error != nil) {
            DDLogError(@"Error opening the database. %@\nDeleting the file and trying again", error);

            SentryStartupEventAddError(startupEvent, error);
            error = nil;

            // make a backup of the old database
            [CoreDataIterativeMigrator backupDatabaseAt:storeURL error:&error];
            if (error != nil) {
                SentryStartupEventAddError(startupEvent, error);
                error = nil;
            }

            [persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *description, NSError *error) {
                SentryStartupEventAddError(startupEvent, error);
                [startupEvent sendWithTitle:@"Can't initialize Core Data stack"];

                @throw [NSException exceptionWithName:@"Can't initialize Core Data stack"
                                               reason:[error localizedDescription]
                                             userInfo:[error userInfo]];
            }];

        }
    }];
    return persistentContainer;
}

- (NSPersistentStoreDescription *)storeDescription
{
    if(_storeDescription) {
        return _storeDescription;
    }

    NSPersistentStoreDescription *storeDescription = [[NSPersistentStoreDescription alloc] initWithURL:self.storeURL];
    storeDescription.shouldInferMappingModelAutomatically = true;
    storeDescription.shouldMigrateStoreAutomatically = true;
    return storeDescription;
}

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
    return self.persistentContainer.persistentStoreCoordinator;
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

- (void)migrateDataModelsIfNecessary:(SentryStartupEvent *)sentryEvent
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

        [CoreDataIterativeMigrator iterativeMigrateWithSourceStore:[self storeURL]
        storeType:NSSQLiteStoreType
               to:self.managedObjectModel
            using:sortedModelNames
            error:&error];

        if (error != nil) {
            DDLogError(@"Unable to migrate store: %@", error);

            SentryStartupEventAddError(sentryEvent, error);
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
