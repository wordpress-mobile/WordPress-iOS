//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>

@interface MPObjectSerializerContext : NSObject

- (id)initWithRootObject:(id)object;

- (BOOL)hasUnvisitedObjects;

- (void)enqueueUnvisitedObject:(NSObject *)object;
- (NSObject *)dequeueUnvisitedObject;

- (void)addVisitedObject:(NSObject *)object;
- (BOOL)isVisitedObject:(NSObject *)object;

- (void)addSerializedObject:(NSDictionary *)serializedObject;
- (NSArray *)allSerializedObjects;

@end
