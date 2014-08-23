//
//  SPMemberInt.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPMemberInt.h"

@implementation SPMemberInt

- (id)defaultValue {
	return @(0);
}

- (NSDictionary *)diff:(id)thisValue otherValue:(id)otherValue {
	NSAssert([thisValue isKindOfClass:[NSNumber class]] && [otherValue isKindOfClass:[NSNumber class]],
			 @"Simperium error: couldn't diff ints because their classes weren't NSNumber");
	
	if ([thisValue isEqualToNumber: otherValue]) {
		return @{ };
	}
    
	// Construct the diff in the expected format
	return @{
		OP_OP : OP_REPLACE,
		OP_VALUE : otherValue
	};
}

- (id)getValueFromDictionary:(NSDictionary *)dict key:(NSString *)key object:(id<SPDiffable>)object {
	id value = [super getValueFromDictionary:dict key:key object:object];
	
	// Failsafe: Attempt to parse the int value
	if ([value isKindOfClass:[NSString class]]) {
		value = @([((NSString *)value) integerValue]);
	}
	
	return value;
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue error:(NSError **)error {
	NSAssert([thisValue isKindOfClass:[NSNumber class]] && [otherValue isKindOfClass:[NSNumber class]],
			 @"Simperium error: couldn't apply diff to ints because their classes weren't NSNumber");
	
	// Integer changes just replace the previous value by default
	// TODO: Not sure if this should be a copy or not...
	return otherValue;
}

- (NSDictionary *)transform:(id)thisValue otherValue:(id)otherValue oldValue:(id)oldValue error:(NSError **)error {
    // By default, don't transform anything, and take the local pending value
    return @{
        OP_OP       : OP_REPLACE,
        OP_VALUE    : thisValue
    };
}

@end
