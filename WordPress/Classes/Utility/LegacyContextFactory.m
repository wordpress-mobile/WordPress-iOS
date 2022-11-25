#import "LegacyContextFactory.h"
#import "WordPress-Swift.h"

@interface LegacyContextFactory()

@property (nonatomic, strong) NSPersistentContainer *container;
@property (nonatomic, strong) NSManagedObjectContext *writerContext;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;

@end

@implementation LegacyContextFactory

- (instancetype)initWithPersistentContainer:(NSPersistentContainer *)container
{
    self = [super init];
    if (self) {
        self.container = container;
        [self createWriterContext];
        [self createMainContext];
        [self startListeningToMainContextNotifications];
    }
    return self;
}

- (NSManagedObjectContext *const)newDerivedContext
{
    return [self newChildContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
}

- (void)createWriterContext
{
    NSAssert(self.writerContext == nil, @"%s should only be called once", __PRETTY_FUNCTION__);

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = self.container.persistentStoreCoordinator;
    
    if ([Feature enabled:FeatureFlagContentMigration]) {
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    }
    
    self.writerContext = context;
}

- (void)createMainContext
{
    NSAssert(self.mainContext == nil, @"%s should only be called once", __PRETTY_FUNCTION__);

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.parentContext = self.writerContext;
    self.mainContext = context;
}

- (NSManagedObjectContext *const)newChildContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc]
                                            initWithConcurrencyType:concurrencyType];
    childContext.parentContext = self.mainContext;
    childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;

    return childContext;
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

@end
