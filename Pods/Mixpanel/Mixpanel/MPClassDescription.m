//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPClassDescription.h"
#import "MPPropertyDescription.h"

@implementation MPClassDescription

{
    NSArray *_propertyDescriptions;
}

- (id)initWithSuperclassDescription:(MPClassDescription *)superclassDescription dictionary:(NSDictionary *)dictionary
{
    self = [super initWithDictionary:dictionary];
    if (self) {
        _superclassDescription = superclassDescription;

        NSMutableArray *propertyDescriptions = [[NSMutableArray alloc] init];
        for (NSDictionary *propertyDictionary in dictionary[@"properties"]) {
            [propertyDescriptions addObject:[[MPPropertyDescription alloc] initWithDictionary:propertyDictionary]];
        }

        _propertyDescriptions = [propertyDescriptions copy];
    }

    return self;
}

- (NSArray *)propertyDescriptions
{
    NSMutableDictionary *allPropertyDescriptions = [[NSMutableDictionary alloc] init];

    MPClassDescription *description = self;
    while (description)
    {
        for (MPPropertyDescription *propertyDescription in description->_propertyDescriptions) {
            if (!allPropertyDescriptions[propertyDescription.name]) {
                allPropertyDescriptions[propertyDescription.name] = propertyDescription;
            }
        }
        description = description.superclassDescription;
    }

    return [allPropertyDescriptions allValues];
}

- (BOOL)isDescriptionForKindOfClass:(Class)class
{
    return [self.name isEqualToString:NSStringFromClass(class)] && [self.superclassDescription isDescriptionForKindOfClass:[class superclass]];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@:%p name='%@' superclass='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.name, self.superclassDescription ? self.superclassDescription.name : @""];
}

@end
