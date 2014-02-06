//
//  SPCoreDataStorage.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-17.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPStorage.h"
#import "SPStorageObserver.h"
#import "SPStorageProvider.h"



@interface SPCoreDataStorage : SPStorage<SPStorageProvider>

@property (nonatomic, strong,  readonly) NSManagedObjectContext			*writerManagedObjectContext;
@property (nonatomic, strong,  readonly) NSManagedObjectContext			*mainManagedObjectContext;
@property (nonatomic, strong,  readonly) NSManagedObjectModel			*managedObjectModel;
@property (nonatomic, strong,  readonly) NSPersistentStoreCoordinator	*persistentStoreCoordinator;
@property (nonatomic, weak,	  readwrite) id<SPStorageObserver>			delegate;

extern NSString* const SPCoreDataBucketListKey;
extern NSString* const SPCoreDataWorkerContext;

+ (BOOL)newCoreDataStack:(NSString *)modelName mainContext:(NSManagedObjectContext **)mainContext model:(NSManagedObjectModel **)model coordinator:(NSPersistentStoreCoordinator **)coordinator;

- (id)initWithModel:(NSManagedObjectModel *)model mainContext:(NSManagedObjectContext *)mainContext coordinator:(NSPersistentStoreCoordinator *)coordinator;

- (NSArray *)exportSchemas;
- (void)setBucketList:(NSDictionary *)dict;

@end
