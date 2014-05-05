#import "CoreDataTestHelper.h"
#import "WordPressAppDelegate.h"
#import <objc/runtime.h>
#import "ContextManager.h"
#import "AsyncTestHelper.h"

@interface ContextManager (TestHelper)

@property (nonatomic, strong) NSManagedObjectContext *rootContext;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

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
    [ContextManager sharedInstance].rootContext = nil;
    [ContextManager sharedInstance].mainContext = nil;
    [ContextManager sharedInstance].persistentStoreCoordinator = nil;
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
    [[ContextManager sharedInstance].rootContext reset];
    [ContextManager sharedInstance].rootContext = nil;
    [[ContextManager sharedInstance].mainContext reset];
    [ContextManager sharedInstance].mainContext = nil;
    [ContextManager sharedInstance].persistentStoreCoordinator = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:[ContextManager sharedInstance]];
    
    [[NSFileManager defaultManager] removeItemAtURL:[ContextManager storeURL] error:nil];
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
@dynamic rootContext;

static void *const testPSCKey = "testPSCKey";

#pragma mark - Override persistent store coordinator

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    id psc = objc_getAssociatedObject(self, testPSCKey);
    if (psc) {
        return psc;
    }
    
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[ContextManager sharedInstance] managedObjectModel]];
    NSError *error;
    NSPersistentStore *store = [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
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
    Method originalSaveChangesInRootContext = class_getInstanceMethod([ContextManager class], @selector(saveChangesInRootContext:));
    Method testSaveChangesInRootContext = class_getInstanceMethod([ContextManager class], @selector(testSaveChangesInRootContext:));
    method_exchangeImplementations(originalSaveChangesInRootContext, testSaveChangesInRootContext);
}

- (void)testSaveChangesInRootContext:(NSNotification *)notification {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] rootContext];
    [context performBlockAndWait:^{
        [context save:nil];
    }];

    if (ATHSemaphore) {
        ATHNotify();
    } else {
        NSLog(@"No semaphore present for notify");
    }
}

@end
