//
//  SPMemberDate.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPMemberDate.h"

@implementation SPMemberDate

- (id)defaultValue {
	return [NSDate date];
}

- (id)dateValueFromNumber:(id)value {
	if ([value isKindOfClass:[NSNumber class]])
		return value;
	
	// Convert from NSDate to NSNumber
	//NSInteger gmtOffset = [[NSTimeZone localTimeZone] secondsFromGMT];
	return [NSNumber numberWithDouble:[value timeIntervalSince1970]];//+gmtOffset];
}

- (id)getValueFromDictionary:(NSDictionary *)dict key:(NSString *)key object:(id<SPDiffable>)object {
    id value = [dict objectForKey: key];
    if (!value)
        return nil;
    
	if ([value isKindOfClass:[NSDate class]])
		return value;
	
	// Convert from NSNumber to NSDate
	//NSInteger gmtOffset = [[NSTimeZone localTimeZone] secondsFromGMT];
	return [NSDate dateWithTimeIntervalSince1970:[(NSString *)value doubleValue]];//-gmtOffset];
}

- (void)setValue:(id)value forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dict {
    id convertedValue = [self dateValueFromNumber: value];
    [dict setValue:convertedValue forKey:key];
}

- (NSDictionary *)diff:(id)thisValue otherValue:(id)otherValue {
	NSAssert([thisValue isKindOfClass:[NSDate class]] && [otherValue isKindOfClass:[NSDate class]],
			 @"Simperium error: couldn't diff dates because their classes weren't NSDate");
    
	// Reduce granularity of timing for now due to rounding errors
    NSTimeInterval delta = [thisValue timeIntervalSinceDate:otherValue];
    
	if (delta > -0.1 && delta < 0.1)
        // effectively equal (no difference)
		return [NSDictionary dictionary];
	
	// Construct the diff in the expected format
	return [NSDictionary dictionaryWithObjectsAndKeys:
			OP_REPLACE, OP_OP,
			[self dateValueFromNumber: otherValue], OP_VALUE, nil];
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue error:(NSError **)error {
	// Expect dates in Number format
	//NSAssert([thisValue isKindOfClass:[NSNumber class]] && [otherValue isKindOfClass:[NSNumber class]],
	//		 @"Simperium error: couldn't diff dates because their classes weren't NSNumber (NSDate not supported directly)");
	
	// Date changes replaces the previous value by default (like ints)
	
	// TODO: Not sure if this should be a copy or not
	return otherValue;
}

@end

