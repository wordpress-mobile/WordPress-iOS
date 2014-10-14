#import "CoreDataTestHelper.h"
#import "WordPressAppDelegate.h"
#import <objc/runtime.h>
#import "ContextManager.h"

@interface ContextManager (TestHelper)

@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (NSURL *)storeURL;

@end

@interface CoreDataTestHelper ()

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@end

@implementation CoreDataTestHelper

+ (instancetype)sharedHelper {
    static CoreDataTestHelper *_sharedHelper = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedHelper = [[self alloc] init];
    });

    return _sharedHelper;
}

- (void)setModelName:(NSString *)modelName {
    _managedObjectModel = [self modelWithName:modelName];
    [ContextManager sharedInstance].mainContext = nil;
    [ContextManager sharedInstance].persistentStoreCoordinator = nil;
}

- (BOOL)migrateToModelName:(NSString *)modelName {
    NSManagedObjectModel *destinationModel = [self modelWithName:modelName];
    NSPersistentStoreCoordinator *psc = [ContextManager sharedInstance].persistentStoreCoordinator;
    NSDictionary *sourceMetadata = [psc metadataForPersistentStore:psc.persistentStores[0]];
    BOOL pscCompatible = [destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
    if (pscCompatible) {
        // Models are compatible, no migration needed
        return YES;
    }

    NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:sourceMetadata];
    if (!sourceModel) {
        // Source model not found
        return NO;
    }

    NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:destinationModel];
    NSMappingModel *mappingModel = [NSMappingModel mappingModelFromBundles:@[[NSBundle mainBundle]] forSourceModel:sourceModel destinationModel:destinationModel];
    if (!mappingModel) {
        // Mapping model not found
        return NO;
    }

    NSError *error;
    NSURL *destinationURL = [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"WordPressTestMigrated.sqlite"]];
    BOOL migrated = [manager migrateStoreFromURL:[ContextManager storeURL]
                                   type:NSSQLiteStoreType
                                options:nil
                       withMappingModel:mappingModel
                       toDestinationURL:destinationURL
                        destinationType:NSSQLiteStoreType
                     destinationOptions:nil
                                  error:&error];
    if (error) {
        NSLog(@"error: %@", error);
        return NO;
    }

    [[NSFileManager defaultManager] removeItemAtURL:[ContextManager storeURL] error:nil];
    [[NSFileManager defaultManager] moveItemAtURL:destinationURL toURL:[ContextManager storeURL] error:nil];

    [self setModelName:modelName];
    return migrated;
}

- (NSManagedObjectModel *)modelWithName:(NSString *)modelName {
    NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:modelName ofType:@"mom" inDirectory:@"WordPress.momd"]];
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (NSManagedObject *)insertEntityIntoMainContextWithName:(NSString *)entityName {
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:[ContextManager sharedInstance].mainContext];
}

- (NSManagedObject *)insertEntityWithName:(NSString *)entityName intoContext:(NSManagedObjectContext*)context {
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
}

- (NSArray *)allObjectsInMainContextForEntityName:(NSString *)entityName {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    return [[ContextManager sharedInstance].mainContext executeFetchRequest:request error:nil];
}

- (NSArray *)allObjectsInContext:(NSManagedObjectContext *)context forEntityName:(NSString *)entityName {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    return [context executeFetchRequest:request error:nil];
}

- (void)reset {
    [[ContextManager sharedInstance].mainContext reset];
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"WordPress" ofType:@"momd"]];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

@end

@implementation ContextManager (TestHelper)

@dynamic mainContext;

static void *const testPSCKey = "testPSCKey";

#pragma mark - Override persistent store coordinator

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    id psc = objc_getAssociatedObject(self, testPSCKey);
    if (psc) {
        return psc;
    }
    
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[ContextManager sharedInstance] managedObjectModel]];
    NSError *error;
    NSPersistentStore *store = [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:[ContextManager storeURL] options:nil error:&error];
    NSAssert(store != nil, @"Can't initialize core data storage");
    
    objc_setAssociatedObject([ContextManager sharedInstance], testPSCKey, psc, OBJC_ASSOCIATION_RETAIN);
    
    return psc;
}

- (void)setPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    objc_setAssociatedObject(self, testPSCKey, persistentStoreCoordinator, OBJC_ASSOCIATION_RETAIN);
}

+ (NSURL *)storeURL {
    return [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"WordPressTest.sqlite"]];
}


#pragma mark - Swizzle save methods

+ (void)load {
    Method originalSaveContext = class_getInstanceMethod([ContextManager class], @selector(saveContext:));
    Method testSaveContext = class_getInstanceMethod([ContextManager class], @selector(testSaveContext:));
    method_exchangeImplementations(originalSaveContext, testSaveContext);
}

- (void)testSaveContext:(NSManagedObjectContext *)context {
	[[ContextManager sharedInstance] saveContext:context withCompletionBlock:^() {
        if ([CoreDataTestHelper sharedHelper].testExpectation) {
            [[CoreDataTestHelper sharedHelper].testExpectation fulfill];
            [CoreDataTestHelper sharedHelper].testExpectation = nil;
        } else {
            NSLog(@"No test expectation present for context save");
        }
    }];
}

@end
