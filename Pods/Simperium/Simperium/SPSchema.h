//
//  SPSchema.h
//  Simperium
//
//  Created by Michael Johnston on 11-05-16.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPDiffable.h"

@class Simperium;
@class SPManagedObject;
@class SPMember;

@interface SPSchema : NSObject

@property (nonatomic, copy)   NSString				*bucketName;
@property (nonatomic, strong) NSMutableDictionary	*members;
@property (nonatomic, strong) NSMutableArray		*binaryMembers;
@property (nonatomic, assign) BOOL					dynamic;

- (id)initWithBucketName:(NSString *)name data:(NSDictionary *)definition;
- (SPMember *)memberForKey:(NSString *)memberName;
- (void)setDefaults:(id<SPDiffable>)object;
- (void)addMemberForObject:(id)object key:(NSString *)key;

@end
