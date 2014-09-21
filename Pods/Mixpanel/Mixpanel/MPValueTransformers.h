//
// Copyright (c) 2014 Mixpanel. All rights reserved.

@interface MPPassThroughValueTransformer : NSValueTransformer

@end

@interface MPBOOLToNSNumberValueTransformer : NSValueTransformer

@end

@interface MPCATransform3DToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface MPCGAffineTransformToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface MPCGColorRefToNSStringValueTransformer : NSValueTransformer

@end

@interface MPCGPointToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface MPCGRectToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface MPCGSizeToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface MPNSAttributedStringToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface MPUIColorToNSStringValueTransformer : NSValueTransformer

@end

@interface MPUIEdgeInsetsToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface MPUIFontToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface MPUIImageToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface MPNSNumberToCGFloatValueTransformer : NSValueTransformer

@end

__unused static id transformValue(id value, NSString *toType)
{
    assert(value != nil);

    if ([value isKindOfClass:[NSClassFromString(toType) class]]) {
        return [[NSValueTransformer valueTransformerForName:@"MPPassThroughValueTransformer"] transformedValue:value];
    }

    NSString *fromType = nil;
    NSArray *validTypes = @[[NSString class], [NSNumber class], [NSDictionary class], [NSArray class], [NSNull class]];
    for (Class c in validTypes) {
        if ([value isKindOfClass:c]) {
            fromType = NSStringFromClass(c);
            break;
        }
    }

    assert(fromType != nil);
    NSValueTransformer *transformer = nil;
    NSString *forwardTransformerName = [NSString stringWithFormat:@"MP%@To%@ValueTransformer", fromType, toType];
    transformer = [NSValueTransformer valueTransformerForName:forwardTransformerName];
    if (transformer) {
        return [transformer transformedValue:value];
    }

    NSString *reverseTransformerName = [NSString stringWithFormat:@"MP%@To%@ValueTransformer", toType, fromType];
    transformer = [NSValueTransformer valueTransformerForName:reverseTransformerName];
    if (transformer && [[transformer class] allowsReverseTransformation]) {
        return [transformer reverseTransformedValue:value];
    }

    return [[NSValueTransformer valueTransformerForName:@"MPPassThroughValueTransformer"] transformedValue:value];
}
