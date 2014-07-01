//
//  SPJSONStorage.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-17.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPJSONStorage.h"
#import "SPObject.h"
#import "SPGhost.h"
#import "NSString+Simperium.h"
#import "NSMutableDictionary+Simperium.h"
#import "SPBucket+Internals.h"
#import "SPSchema.h"
#import "SPDiffer.h"
#import "jrswizzle.h"


@interface NSMutableDictionary ()
- (void)simperiumSetObject:(id)anObject forKey:(id)aKey;
- (void)simperiumSetValue:(id)anObject forKey:(id)aKey;
@end


@implementation SPJSONStorage
@synthesize objects;
@synthesize allObjects;
@synthesize objectList;
@synthesize ghosts;

- (id)initWithDelegate:(id<SPStorageObserver>)aDelegate
{
    if (self = [super init]) {
        delegate = aDelegate;
        self.objects = [NSMutableDictionary dictionaryWithCapacity:10];
        self.ghosts = [NSMutableDictionary dictionaryWithCapacity:10];
        self.allObjects = [NSMutableDictionary dictionaryWithCapacity:10];
        self.objectList = [NSMutableArray arrayWithCapacity:10];
        
        NSString *queueLabel = @"com.simperium.JSONstorage";
        storageQueue = dispatch_queue_create([queueLabel cStringUsingEncoding:NSUTF8StringEncoding], NULL);
        
        NSError *error;
        [NSMutableDictionary jr_swizzleMethod:@selector(setObject:forKey:) withMethod:@selector(simperiumSetObject:forKey:) error:&error];
        [NSMutableDictionary jr_swizzleMethod:@selector(setValue:forKey:) withMethod:@selector(simperiumSetValue:forKey:) error:&error];

    }
    
    return self;
}


- (void)object:(id)object forKey:(NSString *)simperiumKey didChangeValue:(id)value forKey:(NSString *)key {
    // Update the schema if applicable
    SPObject *spObject = [allObjects objectForKey:simperiumKey];
    [spObject.bucket.differ.schema addMemberForObject:value key:key];
    
    // TODO: track the change here so saving can be smart    
}

- (SPStorage *)threadSafeStorage {
    // Accessing objects through any instance of this class is thread-safe (on the main thread)
    return self;
}

- (NSMutableDictionary *)objectDictionaryForBucketName:(NSString *)bucketName {
    return [objects objectForKey:bucketName];
}

- (id)objectForKey:(NSString *)key bucketName:(NSString *)bucketName {
    __block id<SPDiffable>object = nil;
    
    dispatch_sync(storageQueue, ^{
        NSDictionary *objectDict = [objects objectForKey:bucketName];
        if (objectDict)
            object = [objectDict objectForKey:key];
    });
    
    return object;
}

- (NSArray *)objectsForKeys:(NSSet *)keys bucketName:(NSString *)bucketName
{
    __block NSArray *someObjects = nil;
    dispatch_sync(storageQueue, ^{
        NSDictionary *objectDict = [objects objectForKey:bucketName];
        if (objectDict) {
            someObjects = [objectDict objectsForKeys:[keys allObjects] notFoundMarker:[NSNull null]];
        }
    });
    
    if (!someObjects)
        someObjects = [NSArray array];
    
    return someObjects;
}

- (id)objectAtIndex:(NSUInteger)index bucketName:(NSString *)bucketName {
    return nil;
}

- (NSArray *)objectsForBucketName:(NSString *)bucketName predicate:(NSPredicate *)predicate
{ 
    __block NSArray *bucketObjects = nil;
    dispatch_sync(storageQueue, ^{
        NSDictionary *objectDict = [objects objectForKey:bucketName];
        if (objectDict) {
            bucketObjects = [objects allValues];
            
            if (predicate)
                bucketObjects = [bucketObjects filteredArrayUsingPredicate:predicate];
        }
    });
    
    if (!bucketObjects)
        bucketObjects = [NSArray array];
    return bucketObjects;
}

- (NSArray *)objectKeysForBucketName:(NSString *)bucketName {
    __block NSArray *bucketObjects = [self objectsForBucketName:bucketName predicate:nil];
    
    NSMutableArray *keys = [NSMutableArray arrayWithCapacity:[bucketObjects count]];
    for (id<SPDiffable>object in bucketObjects) {
        [keys addObject:[object simperiumKey]];
    }
         
    return keys;
}


- (NSInteger)numObjectsForBucketName:(NSString *)bucketName predicate:(NSPredicate *)predicate
{
    __block NSInteger count = 0;
    dispatch_sync(storageQueue, ^{
        NSDictionary *objectDict = [objects objectForKey:bucketName];
        if (objectDict)
            count = [[[objectDict allValues] filteredArrayUsingPredicate:predicate] count];
    });
    return count;
}

- (NSDictionary *)faultObjectsForKeys:(NSArray *)keys bucketName:(NSString *)bucketName {
    // Batch fault a bunch of objects for efficiency
    // All objects are already in memory, for now at least...
    NSArray *objectsAsList = [self objectsForKeys:[NSSet setWithArray:keys] bucketName:bucketName];
    NSMutableDictionary *objectDict = [NSMutableDictionary dictionaryWithCapacity:[objectList count]];
    for (id<SPDiffable>object in objectsAsList)
        [objectDict setObject:object forKey:object.simperiumKey];
    return objectDict;
}

- (void)refaultObjects:(NSArray *)objects {
//    for (SPManagedObject *object in objects) {
//        [context refreshObject:object mergeChanges:NO];
//    }
}

- (id<SPDiffable>)insertNewObjectForBucketName:(NSString *)bucketName simperiumKey:(NSString *)key
{
    id<SPDiffable>object = [[SPObject alloc] init];
    
    if (!key)
        key = [NSString sp_makeUUID];
    
    dispatch_sync(storageQueue, ^{
        NSMutableDictionary *objectDict = [objects objectForKey:bucketName];
        if (!objectDict) {
            objectDict = [NSMutableDictionary dictionaryWithCapacity:3];
            [objects setObject:objectDict forKey:bucketName];
        }
        object.simperiumKey = key;
        [objectDict setObject:object forKey:key];
        [allObjects setObject:object forKey:key];
    });
    
    return object;
}

- (void)insertObject:(id)dict bucketName:(NSString *)bucketName {
    // object should be a dictionary
    id<SPDiffable>object = [[SPObject alloc] initWithDictionary:dict];

    dispatch_sync(storageQueue, ^{
        NSMutableDictionary *objectDict = [objects objectForKey:bucketName];
        if (!objectDict) {
            objectDict = [NSMutableDictionary dictionaryWithCapacity:3];
            [objects setObject:objectDict forKey:bucketName];
        }
        NSString *key = [NSString sp_makeUUID];
        object.simperiumKey = key;   
        [objectDict setObject:object forKey:key];
        [allObjects setObject:objects forKey:key];
    });
}

- (void)setMetadata:(NSDictionary *)metadata {
    // TODO: support metadata for JSON store
    // [[NSUserDefaults standardUserDefaults] setObject:json forKey: key];
    // [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDictionary *)metadata {
    return nil;
}

- (void)deleteObject:(id)dict
{
    // TODO: this is where an associative reference to simperiumKey on the dict will be needed
//    SPManagedObject *managedObject = (SPManagedObject *)object;
//    [managedObject.managedObjectContext deleteObject:managedObject];
}

- (void)deleteAllObjectsForBucketName:(NSString *)bucketName {
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
//    [fetchRequest setEntity:entity];
//    
//    // No need to fault everything
//    [fetchRequest setIncludesPropertyValues:NO];
//    
//    NSError *error;
//    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
//    
//    for (NSManagedObject *managedObject in items) {
//        [context deleteObject:managedObject];
//    }
//    if (![context save:&error]) {
//        NSLog(@"Simperium error deleting %@ - error:%@",entityName,error);
//    }
}

- (void)validateObjectsForBucketName:(NSString *)bucketName
{
//    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
//    if (entity == nil) {
//        //SPLogWarn(@"Simperium warning: couldn't find any instances for entity named %@", entityName);
//        return;
//    }
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    [request setEntity:entity];
//    
//    // Execute a targeted fetch to preserve faults so that only simperiumKeys are loaded in to memory
//    // http://stackoverflow.com/questions/3956406/core-data-how-to-get-nsmanagedobjects-objectid-when-nsfetchrequest-returns-nsdi
//    NSExpressionDescription* objectIdDesc = [NSExpressionDescription new];
//    objectIdDesc.name = @"objectID";
//    objectIdDesc.expression = [NSExpression expressionForEvaluatedObject];
//    objectIdDesc.expressionResultType = NSObjectIDAttributeType;
//    NSDictionary *properties = [entity propertiesByName];
//    request.resultType = NSDictionaryResultType;
//    request.propertiesToFetch = [NSArray arrayWithObjects:[properties objectForKey:@"simperiumKey"], objectIdDesc, nil];
//    
//    NSError *error = nil;
//    NSArray *results = [context executeFetchRequest:request error:&error];
//    if (results == nil) {
//        // Handle the error.
//        NSAssert1(0, @"Simperium error: couldn't load array of entities (%@)", entityName);
//    }
//    
//    // Check each entity instance
//    for (NSDictionary *result in results) {
//        SPManagedObject *object = (SPManagedObject *)[context objectWithID:[result objectForKey:@"objectID"]];
//        NSString *key = [result objectForKey:@"simperiumKey"];
//        // In apps like Simplenote where legacy data might exist on the device, the simperiumKey might need to
//        // be set manually. Provide that opportunity here.
//        if (key == nil) {
//            if ([object respondsToSelector:@selector(getSimperiumKeyFromLegacyKey)]) {
//                key = [object performSelector:@selector(getSimperiumKeyFromLegacyKey)];
//                //if (key && key.length > 0)
//                //    SPLogVerbose(@"Simperium local entity found without key (%@), porting legacy key: %@", entityName, key);
//            }
//            
//            // If it's still nil (unsynced local change in legacy system), treat it like a newly inserted object:
//            // generate a UUID and mark it for sycing
//            if (key == nil || key.length == 0) {
//                NSLog(@"Simperium local entity found with no legacy key (created offline?); generating one now");
//                key = [NSString makeUUID];
//            }
//            object.simperiumKey = key;
//            
//            // The object is now managed by Simperium, so create a new ghost for it and be sure to configure its definition
//            // (it's likely a legacy object that was fetched before Simperium was started)
//            [self configureNewGhost:object];
//            [object performSelector:@selector(configureDefinition)];
//        }
//    }
//    
//    NSLog(@"Simperium managing %u %@ object instances", [results count], entityName); 
}

- (BOOL)save
{
    // This needs to write all objects to disk in a thread-safe way, perhaps asynchronously since it can be
    // triggered from the main thread and could take awhile
    
    // Sync all changes
    // Fake it for now by trying to send all objects
    NSMutableSet *updatedObjects = [NSMutableSet set];
    for (NSDictionary *objectDict in [objects allValues]) {
        NSArray *objectsAsList = [objectDict allValues];
        [updatedObjects addObjectsFromArray:objectsAsList];
    }
    [delegate storage:self updatedObjects:updatedObjects insertedObjects:nil deletedObjects:nil];

    return NO;
}

- (void)beginSafeSection {
	
}

- (void)finishSafeSection {
	
}

- (void)beginCriticalSection {
	
}

- (void)finishCriticalSection {
	
}

@end
