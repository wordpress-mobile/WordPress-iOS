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
	return [NSNumber numberWithInt:0];
}

- (NSDictionary *)diff:(id)thisValue otherValue:(id)otherValue {
	NSAssert([thisValue isKindOfClass:[NSNumber class]] && [otherValue isKindOfClass:[NSNumber class]],
			 @"Simperium error: couldn't diff ints because their classes weren't NSNumber");
	
	if ([thisValue isEqualToNumber: otherValue])
		return [NSDictionary dictionary];
    
	// Construct the diff in the expected format
	return [NSDictionary dictionaryWithObjectsAndKeys:
			OP_REPLACE, OP_OP,
			otherValue, OP_VALUE, nil];
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue {
	NSAssert([thisValue isKindOfClass:[NSNumber class]] && [otherValue isKindOfClass:[NSNumber class]],
			 @"Simperium error: couldn't apply diff to ints because their classes weren't NSNumber");
	
	// Integer changes just replace the previous value by default
	// TODO: Not sure if this should be a copy or not...
	return otherValue;
}

@end
