#import "TestContextManager.h"
#import "ContextManagerMock.h"
#import "WordPressTest-Swift.h"

// TestContextManager resolves on the Swift or Obj-C Core Data initialization
// Based on the Feature Flag value
@implementation TestContextManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Override the shared ContextManager
        _stack = [[ContextManagerMock alloc] init];
    }

    return self;
}

- (NSManagedObjectModel *)managedObjectModel
{
    return [_stack managedObjectModel];
}

- (void)setManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    [_stack setManagedObjectModel:managedObjectModel];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    return [_stack persistentStoreCoordinator];
}

- (void)setPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    return [_stack setPersistentStoreCoordinator:persistentStoreCoordinator];
}

- (NSPersistentStoreCoordinator *)standardPSC
{
    return [_stack standardPSC];
}

- (NSManagedObjectContext *)mainContext
{
    return [_stack mainContext];
}

- (void)setMainContext:(NSManagedObjectContext *)mainContext
{
    [_stack setMainContext:mainContext];
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    [_stack saveContext:context];
}

- (void)saveContextAndWait:(NSManagedObjectContext *)context
{
    [_stack saveContextAndWait:context];
}

- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock
{
    [_stack saveContext:context withCompletionBlock:completionBlock];
}

- (nonnull NSManagedObjectContext *const)newDerivedContext {
    return [_stack newDerivedContext];
}

- (NSURL *)storeURL
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask,
                                                                        YES) lastObject];

    return [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"WordPressTest.sqlite"]];
}

@end
