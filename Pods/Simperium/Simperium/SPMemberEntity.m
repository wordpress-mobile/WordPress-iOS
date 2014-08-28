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
#import "SPLogger.h"


#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static SPLogLevels logLevel = SPLogLevelsWarn;


#pragma mark ====================================================================================
#pragma mark SPMemberEntity
#pragma mark ====================================================================================

@implementation SPMemberEntity

- (instancetype)initFromDictionary:(NSDictionary *)dict {
    self = [super initFromDictionary:dict];
    if (self) {
        _entityName = dict[@"entityName"];
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
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    fetchRequest.entity     = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:context];
    fetchRequest.predicate  = [NSPredicate predicateWithFormat:@"simperiumKey == %@", key];
    
    NSError *error;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];
    
    return [items firstObject];
}

- (id)getValueFromDictionary:(NSDictionary *)dict key:(NSString *)key object:(id<SPDiffable>)object {
    NSString *simperiumKey = dict[key];
    
    // With optional 1 to 1 relationships, there might not be an object
    if (!simperiumKey || simperiumKey.length == 0) {
        return nil;
    }
    
    SPManagedObject *managedObject = (SPManagedObject *)object;
    id value = [self objectForKey:simperiumKey context:managedObject.managedObjectContext];
    SPBucket *bucket = object.bucket;
    
    if (value == nil) {
        // The object isn't here YET...but it will be LATER
        // This is a convenient place to track references because it's guaranteed to be called from loadMemberData in
        // SPManagedObject when it arrives off the wire.
        NSString *fromKey = object.simperiumKey;
        
        // Failsafe
        if (!fromKey || !simperiumKey) {
            SPLogWarn(@"Simperium couldn't resolve relationship [%@] > [%@] due to a missing key", fromKey, simperiumKey);
            return nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Let Simperium store the reference so it can be properly resolved when the object gets synced
            SPRelationship *relationship = [SPRelationship relationshipFromObjectWithKey:fromKey
                                                                               attribute:self.keyName
                                                                            sourceBucket:bucket.name
                                                                         toObjectWithKey:simperiumKey
                                                                            targetBucket:self.entityName];
            
            [bucket.relationshipResolver addPendingRelationship:relationship];
            [bucket.relationshipResolver saveWithStorage:bucket.storage];
        });
    }
    return value;
}

- (void)setValue:(id)value forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dict {
    id convertedValue = [self simperiumKeyForObject:value];
    [dict setValue:convertedValue forKey:key];
}

- (NSDictionary *)diff:(id)thisValue otherValue:(id)otherValue {
    NSString *otherKey = [self simperiumKeyForObject:otherValue];
    
    NSAssert([thisValue isKindOfClass:[SPManagedObject class]] && [otherValue isKindOfClass:[SPManagedObject class]],
            @"Simperium error: couldn't diff objects because their classes weren't SPManagedObject");
    
    NSString *thisKey = [self simperiumKeyForObject:thisValue];
    
    // No change if the entity keys are equal
    if ([thisKey isEqualToString:otherKey]) {
        return @{ };
    }
    
    // Construct the diff in the expected format
    return [NSDictionary dictionaryWithObjectsAndKeys:OP_REPLACE, OP_OP, otherKey, OP_VALUE, nil];
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue error:(NSError **)error {
    return otherValue;
}

@end
