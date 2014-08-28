//
//  SPRelationship.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 4/21/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import "SPRelationship.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSString * const SPRelationshipsSourceKey        = @"SPRelationshipsSourceKey";
static NSString * const SPRelationshipsSourceBucket     = @"SPRelationshipsSourceBucket";
static NSString * const SPRelationshipsSourceAttribute  = @"SPRelationshipsSourceAttribute";
static NSString * const SPRelationshipsTargetBucket     = @"SPRelationshipsTargetBucket";
static NSString * const SPRelationshipsTargetKey        = @"SPRelationshipsTargetKey";

static NSString * const SPLegacyPathKey                 = @"SPPathKey";
static NSString * const SPLegacyPathBucket              = @"SPPathBucket";
static NSString * const SPLegacyPathAttribute           = @"SPPathAttribute";


#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPRelationship ()
@property (nonatomic, strong) NSString *sourceKey;
@property (nonatomic, strong) NSString *sourceAttribute;
@property (nonatomic, strong) NSString *sourceBucket;
@property (nonatomic, strong) NSString *targetKey;
@property (nonatomic, strong) NSString *targetBucket;
@end


#pragma mark ====================================================================================
#pragma mark SPRelationship
#pragma mark ====================================================================================

@implementation SPRelationship

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    SPRelationship *second = (SPRelationship *)object;
    return  [_sourceKey     isEqual:second.sourceKey]       && [_sourceAttribute isEqual:second.sourceAttribute]    &&
            [_sourceBucket  isEqual:second.sourceBucket]    && [_targetBucket isEqual:second.targetBucket]          &&
            [_targetKey     isEqual:second.targetKey];
}

- (NSUInteger)hash {
    return  [_sourceKey hash] + [_sourceAttribute hash] + [_sourceBucket hash] + [_targetKey hash] + [_targetBucket hash];
}

- (NSDictionary *)toDictionary {
    return @{
        SPRelationshipsSourceKey        : _sourceKey,
        SPRelationshipsSourceBucket     : _sourceBucket,
        SPRelationshipsSourceAttribute  : _sourceAttribute,
        SPRelationshipsTargetBucket     : _targetBucket,
        SPRelationshipsTargetKey        : _targetKey
    };
}


#pragma mark - Public Helpers

+ (NSArray *)serializeFromArray:(NSArray *)relationships {
    
    NSMutableArray *serialized = [NSMutableArray array];
    
    for (SPRelationship *relationship in relationships) {
        [serialized addObject:[relationship toDictionary]];
    }
    
    return serialized;
}

+ (NSArray *)parseFromArray:(NSArray *)rawRelationships {
    
    NSMutableArray *parsed = [NSMutableArray array];
    
    for (NSDictionary *rawRelationship in rawRelationships) {
        NSAssert([rawRelationship isKindOfClass:[NSDictionary class]], @"Invalid Parameter");
        
        SPRelationship *relationship    = [self new];
        relationship.sourceKey          = rawRelationship[SPRelationshipsSourceKey];
        relationship.sourceAttribute    = rawRelationship[SPRelationshipsSourceAttribute];
        relationship.sourceBucket       = rawRelationship[SPRelationshipsSourceBucket];
        relationship.targetKey          = rawRelationship[SPRelationshipsTargetKey];
        relationship.targetBucket       = rawRelationship[SPRelationshipsTargetBucket];
        
        [parsed addObject:relationship];
    }

    return parsed;
}

+ (NSArray *)parseFromLegacyDictionary:(NSDictionary *)rawLegacy {

    NSMutableArray *parsed = [NSMutableArray array];
    
    for (NSString *targetKey in [rawLegacy allKeys]) {
        NSArray *relationships = rawLegacy[targetKey];
        NSAssert([relationships isKindOfClass:[NSArray class]], @"Invalid Kind");
        
        for (NSDictionary *rawRelationship in relationships) {
            NSAssert([rawRelationship isKindOfClass:[NSDictionary class]], @"Invalid Parameter");
            
            SPRelationship *relationship    = [self new];
            relationship.sourceKey          = rawRelationship[SPLegacyPathKey];
            relationship.sourceAttribute    = rawRelationship[SPLegacyPathAttribute];
            relationship.sourceBucket       = rawRelationship[SPLegacyPathBucket];
            relationship.targetKey          = targetKey;
            relationship.targetBucket       = @"";
            
            [parsed addObject:relationship];
        }
    }
    
    return parsed;
}

+ (instancetype)relationshipFromObjectWithKey:(NSString *)sourceKey
                                    attribute:(NSString *)sourceAttribute
                                 sourceBucket:(NSString *)sourceBucket
                              toObjectWithKey:(NSString *)targetKey
                                 targetBucket:(NSString *)targetBucket {
    
    SPRelationship *relationship    = [self new];
    
    relationship.sourceKey          = sourceKey;
    relationship.sourceAttribute    = sourceAttribute;
    relationship.sourceBucket       = sourceBucket;
    relationship.targetKey          = targetKey;
    relationship.targetBucket       = targetBucket;
    
    return relationship;
}

@end
