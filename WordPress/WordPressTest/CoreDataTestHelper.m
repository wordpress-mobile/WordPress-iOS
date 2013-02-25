//
//  CoreDataTestHelper.m
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "CoreDataTestHelper.h"

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

- (id)init {
    self = [super init];
    if (self) {
        _context = [[NSManagedObjectContext alloc] init];
        [_context setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
    }
    return self;
}

- (NSManagedObject *)insertEntityWithName:(NSString *)entityName {
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:_context];
}

- (void)reset {
    [_context lock];
    [_context reset];
    for (NSPersistentStore *store in [_coordinator persistentStores]) {
        [_coordinator removePersistentStore:store error:nil];
    }
    NSAssert([_coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL] ? YES : NO, @"Should be able to add in-memory store");
    [_context unlock];
}

- (NSManagedObjectContext *)managedObjectContext {
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
        NSAssert([_coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL] ? YES : NO, @"Should be able to add in-memory store");
    }
    return _coordinator;
}

@end
