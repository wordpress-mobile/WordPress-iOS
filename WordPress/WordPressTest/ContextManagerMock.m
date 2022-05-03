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

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Override the shared ContextManager
        [ContextManager internalSharedInstance];
        [ContextManager overrideSharedInstance:self];
    }

    return self;
}

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

- (NSManagedObjectContext *)mainContext
{
    if (_mainContext) {
        return _mainContext;
    }

    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainContext.persistentStoreCoordinator = self.persistentStoreCoordinator;

    return _mainContext;
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

- (NSManagedObject *)loadEntityNamed:(NSString *)entityName withContentsOfFile:(NSString *)filename
{
    NSParameterAssert(entityName);

    NSDictionary *dict = [self objectWithContentOfFile:filename];

    // Insert + Set Values
    NSManagedObject *object= [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.mainContext];

    for (NSString *key in dict.allKeys) {
        [object setValue:dict[key] forKey:key];
    }

    return object;
}

- (NSDictionary *)objectWithContentOfFile:(NSString *)filename
{
    NSParameterAssert(filename);

    // Load the Raw JSON
    NSString *name      = filename.stringByDeletingPathExtension;
    NSString *extension = filename.pathExtension;
    NSString *path      = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:extension];
    NSData *contents    = [NSData dataWithContentsOfFile:path];
    NSAssert(contents, @"Mockup data could not be loaded");

    // Parse
    NSDictionary *dict  = [NSJSONSerialization JSONObjectWithData:contents
                                                          options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves
                                                            error:nil];
    NSAssert(dict, @"Mockup data could not be parsed");
    return dict;
}

@end
