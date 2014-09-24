//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPValueTransformers.h"

@implementation MPPassThroughValueTransformer

+ (Class)transformedValueClass
{
    return [NSObject class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if ([[NSNull null] isEqual:value]) {
        return nil;
    }

    if (value == nil) {
        return [NSNull null];
    }

    return value;
}

@end
