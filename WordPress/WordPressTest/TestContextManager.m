#import "TestContextManager.h"
#import "ContextManager-Internals.h"

@implementation TestContextManager

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize mainContext = _mainContext;
@synthesize managedObjectModel = _managedObjectModel;

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Override the shared ContextManager to prevent Simperium from being used
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

    // Insert + Set Values
    NSManagedObject *object= [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.mainContext];
    
    for (NSString *key in dict.allKeys) {
        [object setValue:dict[key] forKey:key];
    }
    
    return object;
}

@end
