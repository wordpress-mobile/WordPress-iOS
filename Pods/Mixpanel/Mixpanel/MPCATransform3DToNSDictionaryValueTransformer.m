//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPValueTransformers.h"

static NSDictionary *MPCATransform3DCreateDictionaryRepresentation(CATransform3D transform)
{
    return @{
            @"m11" : @(transform.m11),
            @"m12" : @(transform.m12),
            @"m13" : @(transform.m13),
            @"m14" : @(transform.m14),

            @"m21" : @(transform.m21),
            @"m22" : @(transform.m22),
            @"m23" : @(transform.m23),
            @"m24" : @(transform.m24),

            @"m31" : @(transform.m31),
            @"m32" : @(transform.m32),
            @"m33" : @(transform.m33),
            @"m34" : @(transform.m34),

            @"m41" : @(transform.m41),
            @"m42" : @(transform.m42),
            @"m43" : @(transform.m43),
            @"m44" : @(transform.m44),
    };
}

static BOOL MPCATransform3DMakeWithDictionaryRepresentation(NSDictionary *dictionary, CATransform3D *transform)
{
    if (transform) {
        id m11 = dictionary[@"m11"];
        id m12 = dictionary[@"m12"];
        id m13 = dictionary[@"m13"];
        id m14 = dictionary[@"m14"];

        id m21 = dictionary[@"m21"];
        id m22 = dictionary[@"m22"];
        id m23 = dictionary[@"m23"];
        id m24 = dictionary[@"m24"];

        id m31 = dictionary[@"m31"];
        id m32 = dictionary[@"m32"];
        id m33 = dictionary[@"m33"];
        id m34 = dictionary[@"m34"];

        id m41 = dictionary[@"m41"];
        id m42 = dictionary[@"m42"];
        id m43 = dictionary[@"m43"];
        id m44 = dictionary[@"m44"];

        if (m11 && m12 && m13 && m14 &&
            m21 && m22 && m23 && m24 &&
            m31 && m32 && m33 && m34 &&
            m41 && m42 && m43 && m44)
        {
            transform->m11 = (CGFloat)[m11 doubleValue];
            transform->m12 = (CGFloat)[m12 doubleValue];
            transform->m13 = (CGFloat)[m13 doubleValue];
            transform->m14 = (CGFloat)[m14 doubleValue];

            transform->m21 = (CGFloat)[m21 doubleValue];
            transform->m22 = (CGFloat)[m22 doubleValue];
            transform->m23 = (CGFloat)[m23 doubleValue];
            transform->m24 = (CGFloat)[m24 doubleValue];

            transform->m31 = (CGFloat)[m31 doubleValue];
            transform->m32 = (CGFloat)[m32 doubleValue];
            transform->m33 = (CGFloat)[m33 doubleValue];
            transform->m34 = (CGFloat)[m34 doubleValue];

            transform->m41 = (CGFloat)[m41 doubleValue];
            transform->m42 = (CGFloat)[m42 doubleValue];
            transform->m43 = (CGFloat)[m43 doubleValue];
            transform->m44 = (CGFloat)[m44 doubleValue];

            return YES;
        }
    }

    return NO;
}

@implementation MPCATransform3DToNSDictionaryValueTransformer

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
    if ([value respondsToSelector:@selector(CATransform3DValue)]) {
        return MPCATransform3DCreateDictionaryRepresentation([value CATransform3DValue]);
    }

    return @{};
}

- (id)reverseTransformedValue:(id)value
{
    CATransform3D transform = CATransform3DIdentity;
    if ([value isKindOfClass:[NSDictionary class]] && MPCATransform3DMakeWithDictionaryRepresentation(value, &transform)) {
        return [NSValue valueWithCATransform3D:transform];
    }

    return [NSValue valueWithCATransform3D:CATransform3DIdentity];
}

@end
