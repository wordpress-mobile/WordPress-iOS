//
//  SPMemberEntity.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPMemberEntity.h"
#import "SPManagedObject.h"
#import "SPBucket+Internals.h"
#import "SPRelationshipResolver.h"

@implementation SPMemberEntity
@synthesize entityName;

- (id)initFromDictionary:(NSDictionary *)dict {
    if (self = [super initFromDictionary:dict]) {
        self.entityName = [dict objectForKey:@"entityName"];
    }
    
    return self;
}


- (id)defaultValue {
	return nil;
}

- (id)simperiumKeyForObject:(id)value {
    NSString *simperiumKey = [value simperiumKey];
	return simperiumKey == nil ? @"" : simperiumKey;
}

- (SPManagedObject *)objectForKey:(NSString *)key context:(NSManagedObjectContext *)context {
    // TODO: could possibly just request a fault?
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    [fetchRequest setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"simperiumKey == %@", key];
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
    
    if ([items count] == 0)
        return nil;
    
    return [items firstObject];
}

- (id)getValueFromDictionary:(NSDictionary *)dict key:(NSString *)key object:(id<SPDiffable>)object {
    NSString *simperiumKey = [dict objectForKey: key];
    
    // With optional 1 to 1 relationships, there might not be an object
    if (!simperiumKey || simperiumKey.length == 0)
        return nil;
        
    SPManagedObject *managedObject = (SPManagedObject *)object;
    id value = [self objectForKey:simperiumKey context:managedObject.managedObjectContext];
    SPBucket *bucket = object.bucket;
    
    if (value == nil) {
        // The object isn't here YET...but it will be LATER
        // This is a convenient place to track references because it's guaranteed to be called from loadMemberData in
        // SPManagedObject when it arrives off the wire.
        NSString *fromKey = object.simperiumKey;
        dispatch_async(dispatch_get_main_queue(), ^{
            // Let Simperium store the reference so it can be properly resolved when the object gets synced
            [bucket.relationshipResolver addPendingRelationshipToKey:simperiumKey fromKey:fromKey bucketName:bucket.name
                                                attributeName:self.keyName storage:bucket.storage];
        });
    }
    return value;
}

- (void)setValue:(id)value forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dict {
    id convertedValue = [self simperiumKeyForObject: value];
    [dict setValue:convertedValue forKey:key];
}

- (NSDictionary *)diff:(id)thisValue otherValue:(id)otherValue {
    NSString *otherKey = [self simperiumKeyForObject:otherValue];
    
	NSAssert([thisValue isKindOfClass:[SPManagedObject class]] && [otherValue isKindOfClass:[SPManagedObject class]],
			 @"Simperium error: couldn't diff objects because their classes weren't SPManagedObject");
    
    NSString *thisKey = [self simperiumKeyForObject:thisValue];
    
    // No change if the entity keys are equal
    if ([thisKey isEqualToString:otherKey])
        return [NSDictionary dictionary];
    
	// Construct the diff in the expected format
	return [NSDictionary dictionaryWithObjectsAndKeys:
			OP_REPLACE, OP_OP,
			otherKey, OP_VALUE, nil];
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue error:(NSError **)error {
	return otherValue;
}

@end
