//
//  SPRelationship.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 4/21/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>



#pragma mark ====================================================================================
#pragma mark SPRelationship
#pragma mark ====================================================================================

@interface SPRelationship : NSObject

@property (nonatomic, strong, readonly) NSString *sourceKey;
@property (nonatomic, strong, readonly) NSString *sourceAttribute;
@property (nonatomic, strong, readonly) NSString *sourceBucket;
@property (nonatomic, strong, readonly) NSString *targetKey;
@property (nonatomic, strong, readonly) NSString *targetBucket;

+ (NSArray *)serializeFromArray:(NSArray *)relationships;

+ (NSArray *)parseFromArray:(NSArray *)rawRelationships;
+ (NSArray *)parseFromLegacyDictionary:(NSDictionary *)rawLegacy;

+ (instancetype)relationshipFromObjectWithKey:(NSString *)sourceKey
                                    attribute:(NSString *)sourceAttribute
                                 sourceBucket:(NSString *)sourceBucket
                              toObjectWithKey:(NSString *)targetKey
                                 targetBucket:(NSString *)targetBucket;

@end
