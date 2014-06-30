//
//  SPStorageProvider.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-17.
//  Copyright (c) 2011 Simperium. All rights reserved.
//
#import "SPDiffable.h"



@protocol SPStorageProvider <NSObject>

- (BOOL)save;
- (NSArray *)objectsForBucketName:(NSString *)bucketName predicate:(NSPredicate *)predicate;
- (NSArray *)objectKeysForBucketName:(NSString *)bucketName;
- (id)objectForKey:(NSString *)key bucketName:(NSString *)bucketName;
- (NSArray *)objectsForKeys:(NSSet *)keys bucketName:(NSString *)bucketName;
- (id)objectAtIndex:(NSUInteger)index bucketName:(NSString *)bucketName;
- (NSInteger)numObjectsForBucketName:(NSString *)bucketName predicate:(NSPredicate *)predicate;
- (NSDictionary *)faultObjectsForKeys:(NSArray *)keys bucketName:(NSString *)bucketName;
- (void)refaultObjects:(NSArray *)objects;
- (void)insertObject:(id)object bucketName:(NSString *)bucketName;
- (id)insertNewObjectForBucketName:(NSString *)bucketName simperiumKey:(NSString *)key;
- (void)deleteObject:(id)object;
- (void)deleteAllObjectsForBucketName:(NSString *)bucketName;
- (void)validateObjectsForBucketName:(NSString *)bucketName;
- (void)stopManagingObjectWithKey:(NSString *)key;
- (id<SPStorageProvider>)threadSafeStorage;
- (void)setMetadata:(NSDictionary *)metadata;
- (NSDictionary *)metadata;
- (void)stashUnsavedObjects;
- (NSArray *)stashedObjects;
- (void)unstashUnsavedObjects;
- (void)unloadAllObjects;

// Synchronization
- (void)beginSafeSection;
- (void)finishSafeSection;
- (void)beginCriticalSection;
- (void)finishCriticalSection;

@optional
- (void)object:(id)object forKey:(NSString *)simperiumKey didChangeValue:(id)value forKey:(NSString *)key;

@end
