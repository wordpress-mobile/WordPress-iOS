//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPValueTransformers.h"


@implementation MPBOOLToNSNumberValueTransformer

+ (Class)transformedValueClass
{
    return [@YES class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if ([value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue] ? @YES : @NO;
    }

    return nil;
}

@end
