//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>
#import "MPTypeDescription.h"

@interface MPClassDescription : MPTypeDescription

- (id)initWithSuperclassDescription:(MPClassDescription *)superclassDescription dictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) MPClassDescription *superclassDescription;
@property (nonatomic, readonly) NSArray *propertyDescriptions;

- (BOOL)isDescriptionForKindOfClass:(Class)class;

@end
