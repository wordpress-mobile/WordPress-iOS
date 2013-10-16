//
//  CoreDataTestHelper.m
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CoreDataTestHelper.h"
#import "WordPressAppDelegate.h"

@interface WordPressAppDelegate (CoreDataTestHelper)
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation CoreDataTestHelper {
    NSManagedObjectContext *_context;
    NSManagedObjectModel *_model;
    NSPersistentStoreCoordinator *_coordinator;
}

+ (id)sharedHelper {
    static CoreDataTestHelper *_sharedHelper = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedHelper = [[self alloc] init];
    });

    return _sharedHelper;
}

- (void)registerDefaultContext {
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    appDelegate.managedObjectContext = [self managedObjectContext];
    appDelegate.persistentStoreCoordinator = [self persistentStoreCoordinator];
    appDelegate.managedObjectModel = [[self persistentStoreCoordinator] managedObjectModel];
}

- (void)unregisterDefaultContext {
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    appDelegate.managedObjectContext = nil;
    appDelegate.persistentStoreCoordinator = nil;
    appDelegate.managedObjectModel = nil;
}

- (void)setModelName:(NSString *)modelName {
    _model = [self modelWithName:modelName];
    _context = nil;
    _coordinator = nil;
}

- (BOOL)migrateToModelName:(NSString *)modelName {
    NSManagedObjectModel *destinationModel = [self modelWithName:modelName];
    NSDictionary *sourceMetadata = [_coordinator metadataForPersistentStore:_coordinator.persistentStores[0]];
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
    BOOL migrated = [manager migrateStoreFromURL:[self storeURL]
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

    [[NSFileManager defaultManager] removeItemAtURL:[self storeURL] error:nil];
    [[NSFileManager defaultManager] moveItemAtURL:destinationURL toURL:[self storeURL] error:nil];

    [self setModelName:modelName];
    return migrated;
}

- (NSManagedObjectModel *)modelWithName:(NSString *)modelName {
    NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:modelName ofType:@"mom" inDirectory:@"WordPress.momd"]];
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (NSManagedObject *)insertEntityWithName:(NSString *)entityName {
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:_context];
}

- (NSArray *)allObjectsForEntityName:(NSString *)entityName
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    return [[self managedObjectContext] executeFetchRequest:request error:nil];
}

- (void)reset {
    [self unregisterDefaultContext];
    [[NSFileManager defaultManager] removeItemAtURL:[self storeURL] error:nil];
    if (!_context) {
        return;
    }
    [_context lock];
    [_context reset];
    if (_coordinator) {
        for (NSPersistentStore *store in [_coordinator persistentStores]) {
            [_coordinator removePersistentStore:store error:nil];
        }
        NSPersistentStore *store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self storeURL] options:nil error:nil];
        NSAssert(store != nil, @"Should be able to add store");
    }
    [_context unlock];
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_context) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_context setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    }
    return _context;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_model) {
        NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"WordPress" ofType:@"momd"]];
        _model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _model;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_coordinator) {
        _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

        NSError *error;
        NSPersistentStore *store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self storeURL] options:nil error:&error];
        NSAssert(store != nil, @"Can't initialize core data storage");
    }
    return _coordinator;
}

- (NSURL *)storeURL {
    return [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: @"WordPressTest.sqlite"]];
}

@end
