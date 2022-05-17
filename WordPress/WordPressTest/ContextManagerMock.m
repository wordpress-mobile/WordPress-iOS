#import "ContextManagerMock.h"

// This deserves a little bit of explanation – this was previously part of the public interface for `ContextManager`, which shouldn't make this API
// public to the hosting app. Rather than rework the `CoreDataMigrationTests` right away (which will be done later as part of adopting Woo's
// updated and well-tested migrator), we can use this hack for now to preserve the behaviour for those tests and come back to them later.
@interface ContextManager(DeprecatedAccessors)
    - (NSPersistentStoreCoordinator *) persistentStoreCoordinator;
    - (NSManagedObjectModel *) managedObjectModel;
@end

@implementation ContextManagerMock

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize mainContext = _mainContext;
@synthesize managedObjectModel = _managedObjectModel;

- (NSManagedObjectModel *)managedObjectModel
{
    return _managedObjectModel ?: [super managedObjectModel];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }

    // This is important for automatic version migration. Leave it here!
    NSDictionary *options = @{
        NSInferMappingModelAutomaticallyOption          : @(YES),
        NSMigratePersistentStoresAutomaticallyOption    : @(YES)
    };

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                   initWithManagedObjectModel:self.managedObjectModel];

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                   configuration:nil
                                                             URL:nil
                                                         options:options
                                                           error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}

- (NSPersistentStoreCoordinator *)standardPSC
{
    return [super persistentStoreCoordinator];
}

- (void)createMainContext
{
    self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.mainContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
}

- (void)saveContextAndWait:(NSManagedObjectContext *)context
{
    [super saveContextAndWait:context];
    // FIXME: Remove this method to use superclass one instead
    // This log magically resolves a deadlock in
    // `ZDashboardCardTests.testShouldNotShowQuickStartIfDefaultSectionIsSiteMenu`
    NSLog(@"Context save completed");
}

- (NSURL *)storeURL
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask,
                                                                        YES) lastObject];

    return [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"WordPressTest.sqlite"]];
}

- (void)setUpAsSharedInstance
{
    [ContextManager internalSharedInstance];
    [ContextManager overrideSharedInstance:self];
}

- (void)tearDown
{
    [self.mainContext reset];

    if ([ContextManager sharedInstance] == self) {
        [ContextManager overrideSharedInstance:nil];
    }
}

@end
