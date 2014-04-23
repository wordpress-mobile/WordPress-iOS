#import "CoreDataTestHelper.h"
#import "WordPressAppDelegate.h"
#import <objc/runtime.h>
#import "ContextManager.h"
#import "AsyncTestHelper.h"

@interface ContextManager (TestHelper)

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

- (NSArray *)allObjectsInMainContextForEntityName:(NSString *)entityName {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    return [[ContextManager sharedInstance].mainContext executeFetchRequest:request error:nil];
}

- (void)reset {
	NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
	NSPersistentStoreCoordinator *coordinator = [[ContextManager sharedInstance] persistentStoreCoordinator];
	
	[context lock];
    [context reset];
	
	NSError *error = nil;
	for (NSPersistentStore *store in coordinator.persistentStores) {
		BOOL success = [coordinator removePersistentStore:store error:&error];
		NSAssert(success, @"Error removing PSC: %@", error);
	}
	
    [coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
	NSAssert(error == nil, @"Error adding PSC: %@", error);
	
	[context unlock];
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

static void *const testPSCKey = "testPSCKey";

@dynamic mainContext;

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

@end
