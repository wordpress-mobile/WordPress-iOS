//
//  SPMemberBase64.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPMemberBase64.h"
#import "NSData+Simperium.h"
#import "NSString+Simperium.h"

@implementation SPMemberBase64

- (id)defaultValue {
	return nil;
}

- (NSString *)stringValueFromTransformable:(id)value {
    if (value == nil)
        return @"";
    
    // Convert from a Transformable class to a base64 string
    NSData *data = (self.valueTransformerName ?
                    [[NSValueTransformer valueTransformerForName:self.valueTransformerName] transformedValue:value] :
                    [NSKeyedArchiver archivedDataWithRootObject:value]);
    
    NSString *base64 = [NSString sp_encodeBase64WithData:data];
    //NSLog(@"Simperium transformed base64 (%@) %@ to %@", keyName, value, base64);
	return base64;
}

- (id)getValueFromDictionary:(NSDictionary *)dict key:(NSString *)key object:(id<SPDiffable>)object {
    id value = [dict objectForKey: key];
	if (![value isKindOfClass:[NSString class]])
		return value;
    
	// Convert from NSString (base64) to NSData
    NSData *data = [NSData sp_decodeBase64WithString:value];
    id obj = (self.valueTransformerName ?
              [[NSValueTransformer valueTransformerForName:self.valueTransformerName] reverseTransformedValue:data] :
              [NSKeyedUnarchiver unarchiveObjectWithData:data]);
    
    //NSLog(@"Simperium transforming base64 (%@) %@ from %@", keyName, obj, value);
    
    // A nil value will be encoded as an empty string, so check for that
    if (obj == nil || ([obj isKindOfClass:[NSString class]] && [obj length] == 0))
        return nil;
    
    //NSAssert2(obj != nil, @"Simperium error: Transformable %@ couldn't be parsed from base64: %@", keyName, value);
    
    return obj;
}

- (void)setValue:(id)value forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dict {
    id convertedValue = [self stringValueFromTransformable: value];
    [dict setValue:convertedValue forKey:key];
}

- (NSDictionary *)diff:(id)thisValue otherValue:(id)otherValue {	
    
    if ([thisValue isEqual: otherValue])
        return [NSDictionary dictionary];
    
    // Some binary data, like UIImages, won't detect equality with isEqual:
    // Therefore, compare base64 instead; this can be very slow
    // TODO: think of better ways to handle this
    NSString *thisStr = [self stringValueFromTransformable:thisValue];
    NSString *otherStr = [self stringValueFromTransformable:otherValue];
    if ([thisStr compare:otherStr] == NSOrderedSame)
        return [NSDictionary dictionary];
    
	// Construct the diff in the expected format
	return [NSDictionary dictionaryWithObjectsAndKeys:
			OP_REPLACE, OP_OP,
			[self stringValueFromTransformable: otherValue], OP_VALUE, nil];
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue error:(NSError **)error {
	
	return otherValue;
}

@end
