#import "TestContextManager.h"
#import "ContextManager-Internals.h"

@implementation TestContextManager

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize mainContext = _mainContext;

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Override the shared ContextManager to prevent Simperium from being used
        [ContextManager overrideSharedInstance:self];
    }
    return self;
}

- (void)dealloc
{
    [ContextManager overrideSharedInstance:nil];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    // This is important for automatic version migration. Leave it here!
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption            : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption    : @(YES)
                              };
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                   initWithManagedObjectModel:[self managedObjectModel]];
    
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

- (NSManagedObjectContext *)mainContext
{
    if (_mainContext) {
        return _mainContext;
    }
    
    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    
    return _mainContext;
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    [self saveContext:context withCompletionBlock:^{
        if (self.testExpectation) {
            [self.testExpectation fulfill];
            self.testExpectation = nil;
        } else {
            NSLog(@"No test expectation present for context save");
        }
    }];
}

- (void)resetContextManager
{
    [ContextManager overrideSharedInstance:nil];
}

@end
