#import "ContextManager.h"
#import "LegacyContextFactory.h"
#import "WordPress-Swift.h"
@import WordPressShared.WPAnalytics;
@import Foundation;

#define SentryStartupEventAddError(event, error) [event addError:error file:__FILE__ function:__FUNCTION__ line:__LINE__]

NSString * const ContextManagerModelNameCurrent = @"$CURRENT";

// MARK: - Static Variables
//
static ContextManager *_instance;


// MARK: - Private Properties
//
@interface ContextManager ()

@property (nonatomic, strong) NSPersistentStoreDescription *storeDescription;
@property (nonatomic, strong) NSPersistentContainer *persistentContainer;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, assign) BOOL migrationFailed;
@property (nonatomic, strong) NSString *modelName;
@property (nonatomic, strong) NSURL *storeURL;
@property (nonatomic, strong) id<ManagedObjectContextFactory> contextFactory;
@property (nonatomic, strong) NSOperationQueue *remoteChangeQueue;
@property (nonatomic, strong) NSPersistentHistoryToken *historyToken;
@property (nonatomic, strong) id updateUIObserver;

@end


// MARK: - ContextManager
//
@implementation ContextManager

- (instancetype)init
{
    NSURL *storeURL;
    if ([self isSharedLoginEnabled]) {
        [self copyDatabaseToSharedDirectoryIfNeeded];
        storeURL = [self sharedDatabasePath];
    } else {
        storeURL = [self localDatabasePath];
    }

    return [self initWithModelName:ContextManagerModelNameCurrent storeURL:storeURL contextFactory:nil];
}

- (instancetype)initWithModelName:(NSString *)modelName storeURL:(NSURL *)storeURL contextFactory:(Class)factory
{
    self = [super init];
    if (self) {
        if (factory == nil) {
            factory = [Feature enabled:FeatureFlagNewCoreDataContext] ? [ContainerContextFactory class] : [LegacyContextFactory class];
        }

        NSParameterAssert([modelName isEqualToString:ContextManagerModelNameCurrent] || [modelName hasPrefix:@"WordPress "]);
        NSParameterAssert([storeURL isFileURL]);
        NSParameterAssert([factory conformsToProtocol:@protocol(ManagedObjectContextFactory)]);

        self.modelName = modelName;
        self.storeURL = storeURL;

        [NSValueTransformer registerCustomTransformers];
        self.contextFactory = (id<ManagedObjectContextFactory>)[[factory alloc] initWithPersistentContainer:self.persistentContainer];
        [[[NullBlogPropertySanitizer alloc] initWithContext:self.contextFactory.mainContext] sanitize];
        
        if ([self isSharedLoginEnabled]) {
            [self observeStoreChanges];
        }
    }

    return self;
}

+ (instancetype)internalSharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[ContextManager alloc] init];
    });

    return _instance;
}

+ (NSURL *)inMemoryStoreURL
{
    return [NSURL fileURLWithPath:@"/dev/null"];
}

#pragma mark - Contexts

- (NSManagedObjectContext *)mainContext
{
    return self.contextFactory.mainContext;
}

- (NSManagedObjectContext *const)newDerivedContext
{
    return [self.contextFactory newDerivedContext];
}

#pragma mark - Context Saving and Merging

- (void)saveContextAndWait:(NSManagedObjectContext *)context
{
    [self.contextFactory saveContext:context andWait:YES withCompletionBlock:nil];
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    [self.contextFactory saveContext:context andWait:NO withCompletionBlock:nil];
}

- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock
{
    [self.contextFactory saveContext:context andWait:NO withCompletionBlock:completionBlock];
}

- (void)performAndSaveUsingBlock:(void (^)(NSManagedObjectContext *context))aBlock
{
    NSManagedObjectContext *context = [self newDerivedContext];
    [context performBlockAndWait:^{
        aBlock(context);

        [self saveContextAndWait:context];
    }];
}

- (void)performAndSaveUsingBlock:(void (^)(NSManagedObjectContext *context))aBlock completion:(void (^)(void))completion
{
    NSManagedObjectContext *context = [self newDerivedContext];
    [context performBlock:^{
        aBlock(context);

        [self.contextFactory saveContext:context andWait:NO withCompletionBlock:completion];
    }];
}

#pragma mark - Store Changes

- (void)observeStoreChanges
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleStoreChanges:)
                                                 name:NSPersistentStoreRemoteChangeNotification
                                               object:self.persistentContainer.persistentStoreCoordinator];
}

- (void)handleStoreChanges:(NSNotification *)notification
{
    NSLog(@"[CM]: Persistent store remote change notification");
    __weak __typeof(self) weakSelf = self;
    [self.remoteChangeQueue addOperationWithBlock:^{
        [weakSelf proccessRemoteChanges];
    }];
}

- (void)proccessRemoteChanges
{
    NSLog(@"[CM]: Processing remote changes");
    NSManagedObjectContext *context = [self newDerivedContext];
    [context performBlockAndWait:^{
        NSPersistentHistoryChangeRequest *historyChangeRequest = [NSPersistentHistoryChangeRequest fetchHistoryAfterToken:self.historyToken];
        NSFetchRequest *fetchRequest = [NSPersistentHistoryTransaction fetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"bundleID != %@", [[NSBundle mainBundle] bundleIdentifier]];
        historyChangeRequest.fetchRequest = fetchRequest;
        NSPersistentHistoryResult *result = [context executeRequest:historyChangeRequest error:nil];
        NSArray<NSPersistentHistoryTransaction *> *transactions = result.result;
        
        if (transactions.count > 0) {
            for (NSPersistentHistoryTransaction *transaction in transactions) {
                NSDictionary *userInfo = transaction.objectIDNotification.userInfo;
                
                if (userInfo) {
                    NSLog(@"[CM]: Merging into main context %@", userInfo);
                    [NSManagedObjectContext mergeChangesFromRemoteContextSave:userInfo
                                                                 intoContexts:@[self.mainContext]];
                }
            }
            [self saveContext:self.mainContext];
            self.historyToken = transactions.lastObject.token;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleUIUpdate];
            });
        } else {
            NSLog(@"[CM]: No transactions");
        }
    
    }];
}

- (void)handleUIUpdate
{
    UIApplicationState state = UIApplication.sharedApplication.applicationState;
    
    void (^showUI)(void) = ^{
        NSLog(@"[CM]: Updating UI if necessary");

        WordPressAppDelegate *delegate = (WordPressAppDelegate *) UIApplication.sharedApplication.delegate;
        if (AccountHelper.isLoggedIn) {
            [WPTabBarController.sharedInstance reloadSplitViewControllers];
            [delegate.windowManager showAppUIFor:nil completion:nil];
        } else {
            [delegate.windowManager showFullscreenSignIn];
        }
    };
    if (state == UIApplicationStateActive) {
        showUI();
    } else if (!self.updateUIObserver) {
        __weak __typeof(self) weakSelf = self;
        self.updateUIObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                                object:nil
                                                                                 queue:[NSOperationQueue mainQueue]
                                                                            usingBlock:^(NSNotification * _Nonnull note) {
            showUI();
            [[NSNotificationCenter defaultCenter] removeObserver:weakSelf.updateUIObserver];
            weakSelf.updateUIObserver = nil;
        }];
    }
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
    _persistentContainer = persistentContainer;
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
    
    if ([self isSharedLoginEnabled]) {
        [storeDescription setOption:@YES forKey:NSPersistentHistoryTrackingKey];
        [storeDescription setOption:@YES forKey:NSPersistentStoreRemoteChangeNotificationPostOptionKey];
    }
    
    return storeDescription;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    NSString *modelPath = [self modelPath];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    if ([self.modelName isEqualToString:ContextManagerModelNameCurrent]) {
        // Use the current version defined in data model.
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    } else {
        // Find the specific version defined in data model.
        NSURL *versionedModelURL = [[modelURL URLByAppendingPathComponent:self.modelName] URLByAppendingPathExtension:@"mom"];
        NSAssert([NSFileManager.defaultManager fileExistsAtPath:versionedModelURL.path],
                 @"Can't find model '%@' at %@", self.modelName, modelPath);
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:versionedModelURL];
    }
    return _managedObjectModel;
}

- (NSOperationQueue *)remoteChangeQueue
{
    if (_remoteChangeQueue) {
        return _remoteChangeQueue;
    }
    
    _remoteChangeQueue = [[NSOperationQueue alloc] init];
    _remoteChangeQueue.maxConcurrentOperationCount = 1;
    return _remoteChangeQueue;
}

- (void)setHistoryToken:(NSPersistentHistoryToken *)historyToken
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:historyToken
                                         requiringSecureCoding:YES
                                                         error:nil];
    
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"transactionHistoryToken"];
}

- (NSPersistentHistoryToken *)historyToken
{
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"transactionHistoryToken"];
    if (data) {
        NSPersistentHistoryToken *token = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSPersistentHistoryToken class]
                                                                            fromData:data
                                                                               error:nil];
        return token;
    }
    
    return nil;
}


#pragma mark - Private Helpers

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

- (NSString *)modelPath
{
    return [[NSBundle mainBundle] pathForResource:@"WordPress" ofType:@"momd"];
}

- (BOOL)isSharedLoginEnabled
{
   return [Feature enabled:FeatureFlagSharedLogin];
}

- (NSURL *)localDatabasePath
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask,
                                                                        YES) lastObject];
    return [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"WordPress.sqlite"]];
}

- (NSURL *)sharedDatabasePath
{
    NSURL *sharedDirectory = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.org.wordpress"];
    return [sharedDirectory URLByAppendingPathComponent:@"WordPress.sqlite"];
}

- (void)copyDatabaseToSharedDirectoryIfNeeded
{
    BOOL sharedDatabaseExists = [[NSFileManager defaultManager] fileExistsAtPath:[[self sharedDatabasePath] absoluteString]];
    if (![self isSharedLoginEnabled] || sharedDatabaseExists || AppConfiguration.isJetpack) {
        return;
    }
    
    NSString *shmLocalFilePath = [[[self localDatabasePath] absoluteString] stringByAppendingString:@"-shm"];
    NSString *walLocalFilePath = [[[self localDatabasePath] absoluteString] stringByAppendingString:@"-wal"];
    NSString *shmSharedFilePath = [[[self sharedDatabasePath] absoluteString] stringByAppendingString:@"-shm"];
    NSString *walSharedFilePath = [[[self sharedDatabasePath] absoluteString] stringByAppendingString:@"-wal"];
    [[NSFileManager defaultManager] copyItemAtURL:[self localDatabasePath] toURL:[self sharedDatabasePath] error:nil];
    [[NSFileManager defaultManager] copyItemAtURL:[NSURL URLWithString:shmLocalFilePath] toURL:[NSURL URLWithString:shmSharedFilePath] error:nil];
    [[NSFileManager defaultManager] copyItemAtURL:[NSURL URLWithString:walLocalFilePath] toURL:[NSURL URLWithString:walSharedFilePath] error:nil];
}

@end
