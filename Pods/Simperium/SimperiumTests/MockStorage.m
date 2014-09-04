//
//  MockStorage.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 4/17/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import "MockStorage.h"
#import "SPObject.h"
#import "NSString+Simperium.h"



static NSInteger const SPWorkersDone = 0;


@interface MockStorage ()
@property (nonatomic, strong) NSMutableDictionary   *storage;
@property (nonatomic, strong) NSMutableDictionary   *metadata;
@property (nonatomic, strong) NSConditionLock       *mutex;
@end


@implementation MockStorage

- (instancetype)init {
    if ((self = [super init])) {
        self.storage    = [NSMutableDictionary dictionary];
        self.metadata   = [NSMutableDictionary dictionary];
		self.mutex      = [[NSConditionLock alloc] initWithCondition:SPWorkersDone];
    }
    return self;
}

- (BOOL)save {
    // No-Op
    return YES;
}

- (NSArray *)objectsForBucketName:(NSString *)bucketName predicate:(NSPredicate *)predicate {
    NSArray *objects = [self.storage[bucketName] allValues];
    return [objects filteredArrayUsingPredicate:predicate];
}

- (NSArray *)objectKeysForBucketName:(NSString *)bucketName {
    return [self.storage[bucketName] allKeys];
}

- (id)objectForKey:(NSString *)key bucketName:(NSString *)bucketName {
    return self.storage[bucketName][key];
}

- (NSArray *)objectsForKeys:(NSSet *)keys bucketName:(NSString *)bucketName {
    NSMutableArray *array = [NSMutableArray array];
    
    for (NSString *key in keys) {
        id object = [self objectForKey:key bucketName:bucketName];
        if (object) {
            [array addObject:object];
        }
    }
    
    return array;
}

- (id)objectAtIndex:(NSUInteger)index bucketName:(NSString *)bucketName {
    // Not supported
    return nil;
}

- (NSInteger)numObjectsForBucketName:(NSString *)bucketName predicate:(NSPredicate *)predicate {
    NSArray *objects = [self.storage[bucketName] allValues];
    if (predicate) {
        return [[objects filteredArrayUsingPredicate:predicate] count];
    } else {
        return objects.count;
    }
}

- (NSDictionary *)faultObjectsForKeys:(NSArray *)keys bucketName:(NSString *)bucketName {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    
    for (NSString *key in keys) {
        id object = [self objectForKey:key bucketName:bucketName];
        if (object) {
            dictionary[key] = object;
        }
    }
    
    return dictionary;
}

- (void)refaultObjects:(NSArray *)objects {
    // No-Op
}

- (void)insertObject:(id)object bucketName:(NSString *)bucketName {
    if ([object isKindOfClass:[SPObject class]] == NO) {
        return;
    }
    
    // Load the bucket
    NSMutableDictionary *bucket = self.storage[bucketName];
    if (!bucket) {
        bucket = [NSMutableDictionary dictionary];
        self.storage[bucketName] = bucket;
    }
    
    // Insert
    SPObject *theObject = (SPObject *)object;
    bucket[theObject.simperiumKey] = object;

}

- (id)insertNewObjectForBucketName:(NSString *)bucketName simperiumKey:(NSString *)key {
    // Not supported
    return nil;
}

- (void)deleteObject:(id)object {
    SPObject *theObject = (SPObject *)object;
    if ([theObject isKindOfClass:[SPObject class]]) {
        [self stopManagingObjectWithKey:theObject.simperiumKey];
    }
}

- (void)deleteAllObjectsForBucketName:(NSString *)bucketName {
    [self.storage removeObjectForKey:bucketName];
}

- (void)validateObjectsForBucketName:(NSString *)bucketName {
    // No-Op
}

- (void)stopManagingObjectWithKey:(NSString *)key {
    for (NSMutableDictionary *bucket in self.storage.allValues) {
        [bucket removeObjectForKey:key];
    }
}

- (id<SPStorageProvider>)threadSafeStorage {
    return self;
}

- (void)stashUnsavedObjects {
    // No-Op
}

- (NSArray *)stashedObjects {
    // No-Op
    return nil;
}

- (void)unstashUnsavedObjects {
    // No-Op
}

- (void)unloadAllObjects {
    // No-Op
}

- (void)beginSafeSection {
	NSAssert([NSThread isMainThread] == false, @"It is not recommended to use this method on the main thread");
    
	[_mutex lock];
	NSInteger workers = _mutex.condition + 1;
	[_mutex unlockWithCondition:workers];
}

- (void)finishSafeSection {
	
	[_mutex lock];
	NSInteger workers = _mutex.condition - 1;
	[_mutex unlockWithCondition:workers];
}

- (void)beginCriticalSection {
	NSAssert([NSThread isMainThread] == false, @"It is not recommended to use this method on the main thread");
    
	[_mutex lockWhenCondition:SPWorkersDone];
}

- (void)finishCriticalSection {
	[_mutex unlock];
}

@end
