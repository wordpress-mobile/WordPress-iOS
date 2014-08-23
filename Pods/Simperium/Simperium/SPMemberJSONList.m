//
//  SPMemberJSONList.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPMemberJSONList.h"
#import "JSONKit+Simperium.h"

@implementation SPMemberJSONList

- (id)defaultValue {
	return @"[]";
}

- (id)stringValueFromArray:(id)value {
    if ([value length] == 0)
        return [[self defaultValue] sp_objectFromJSONString];
	return [value sp_objectFromJSONString];
}

- (id)getValueFromDictionary:(NSDictionary *)dict key:(NSString *)key object:(id<SPDiffable>)object {
    id value = [dict objectForKey: key];
	return [value sp_JSONString];
}

- (void)setValue:(id)value forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dict {
    id convertedValue = [self stringValueFromArray: value];
    [dict setValue:convertedValue forKey:key];
}

- (NSDictionary *)diff:(id)thisValue otherValue:(id)otherValue {
	NSAssert([thisValue isKindOfClass:[NSString class]] && [otherValue isKindOfClass:[NSString class]],
			 @"Simperium error: couldn't diff JSON lists because their classes weren't NSString");
    
	// TODO: proper list diff; for now just replace
    
    if ([thisValue isEqualToString: otherValue])
		return [NSDictionary dictionary];
    
	// Construct the diff in the expected format
	return [NSDictionary dictionaryWithObjectsAndKeys:
			OP_REPLACE, OP_OP,
			[self stringValueFromArray: otherValue], OP_VALUE, nil];
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue error:(NSError **)error {
    // TODO: proper list diff, including transform

	return otherValue;
}

@end
