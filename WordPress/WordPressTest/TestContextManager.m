#import "TestContextManager.h"
#import "ContextManagerMock.h"
#import "WordPressTest-Swift.h"

// TestContextManager resolves on the Swift or Obj-C Core Data initialization
// Based on the Feature Flag value
@implementation TestContextManager

static TestContextManager *_instance;

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Override the shared ContextManager
        _stack = [[ContextManagerMock alloc] init];
        _requiresTestExpectation = YES;
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

-(void)setTestExpectation:(XCTestExpectation *)testExpectation
{
    [_stack setTestExpectation:testExpectation];
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    [self saveContext:context withCompletionBlock:^{
        if (self.stack.testExpectation) {
            [self.stack.testExpectation fulfill];
            self.stack.testExpectation = nil;
        } else if (self.stack.requiresTestExpectation) {
            NSLog(@"No test expectation present for context save");
        }
    }];
}

- (void)saveContextAndWait:(NSManagedObjectContext *)context
{
    [_stack saveContextAndWait:context];
    if (self.stack.testExpectation) {
        [self.stack.testExpectation fulfill];
        self.stack.testExpectation = nil;
    } else if (self.stack.requiresTestExpectation) {
        NSLog(@"No test expectation present for context save");
    }
}

- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock
{
    [_stack saveContext:context withCompletionBlock:^{
        if (self.stack.testExpectation) {
            [self.stack.testExpectation fulfill];
            self.stack.testExpectation = nil;
        } else if (self.stack.requiresTestExpectation) {
            NSLog(@"No test expectation present for context save");
        }
        completionBlock();
    }];
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

+ (instancetype)sharedInstance
{
    if (_instance) {
        return _instance;
    }

    _instance = [[TestContextManager alloc] init];
    return _instance;
}

+ (void)overrideSharedInstance:(id <CoreDataStack> _Nullable)contextManager
{
    [ContextManager overrideSharedInstance: contextManager];
}

@end
