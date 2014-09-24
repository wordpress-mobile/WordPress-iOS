//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPValueTransformers.h"


@implementation MPCGRectToNSDictionaryValueTransformer

+ (Class)transformedValueClass
{
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    if ([value respondsToSelector:@selector(CGRectValue)]) {
        CGRect rect = [value CGRectValue];
        rect.origin.x = isnormal(rect.origin.x) ? rect.origin.x : 0.0f;
        rect.origin.y = isnormal(rect.origin.y) ? rect.origin.y : 0.0f;
        rect.size.width = isnormal(rect.size.width) ? rect.size.width : 0.0f;
        rect.size.height = isnormal(rect.size.height) ? rect.size.height : 0.0f;
        return CFBridgingRelease(CGRectCreateDictionaryRepresentation(rect));
    }

    return nil;
}

- (id)reverseTransformedValue:(id)value
{
    CGRect rect = CGRectZero;
    if ([value isKindOfClass:[NSDictionary class]] && CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)value, &rect)) {
        return [NSValue valueWithCGRect:rect];
    }

    return [NSValue valueWithCGRect:CGRectZero];
}

@end
