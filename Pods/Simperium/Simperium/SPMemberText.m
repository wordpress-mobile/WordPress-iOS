//
//  SPMemberText.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPMemberText.h"
#import "DiffMatchPatch.h"

@implementation SPMemberText

- (id)initFromDictionary:(NSDictionary *)dict
{
    if (self = [super initFromDictionary:dict]) {
        dmp = [[DiffMatchPatch alloc] init];
    }
    return self;
}


- (id)defaultValue {
	return @"";
}

- (NSDictionary *)diff:(id)thisValue otherValue:(id)otherValue {
	NSAssert([thisValue isKindOfClass:[NSString class]] && [otherValue isKindOfClass:[NSString class]],
			 @"Simperium error: couldn't diff strings because their classes weren't NSString");
	
	// Use DiffMatchPatch to find the diff
	// Use some logic from MobWrite to clean stuff up
	NSMutableArray *diffList = [dmp diff_mainOfOldString:thisValue andNewString:otherValue];
	if ([diffList count] > 2) {
		[dmp diff_cleanupSemantic:diffList];
		[dmp diff_cleanupEfficiency:diffList];
	}
	
	if ([diffList count] > 0 && [dmp diff_levenshtein:diffList] != 0) {
		// Construct the patch delta and return it as a change operation
		NSString *delta = [dmp diff_toDelta:diffList];
		return [NSDictionary dictionaryWithObjectsAndKeys:
				OP_STRING, OP_OP,
				delta, OP_VALUE, nil];
	}
    
	// No difference
	return [NSDictionary dictionary];
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue {
	// DMP stuff, TODO: error handling
	NSError *error;
    
    // Special case if there was no previous value
    // REMOVED THIS: causes an actual diff (e.g. "+H") to be entered as the new value
    //if ([thisValue length] == 0)
    //    return otherValue;
    
	NSMutableArray *diffs = [dmp diff_fromDeltaWithText:thisValue andDelta:otherValue error:&error];
	NSMutableArray *patches = [dmp patch_makeFromOldString:thisValue andDiffs:diffs];
	NSArray *result = [dmp patch_apply:patches toString:thisValue];
    
	return [result objectAtIndex:0];
}

- (NSDictionary *)transform:(id)thisValue otherValue:(id)otherValue oldValue:(id)oldValue {
	// Assorted hocus pocus ported from JS code
	NSError *error;
	NSMutableArray *thisDiffs = [dmp diff_fromDeltaWithText:oldValue andDelta:thisValue error:&error];
	NSMutableArray *otherDiffs = [dmp diff_fromDeltaWithText:oldValue andDelta:otherValue error:&error];
	NSMutableArray *thisPatches = [dmp patch_makeFromOldString:oldValue andDiffs:thisDiffs];
	NSMutableArray *otherPatches = [dmp patch_makeFromOldString:oldValue andDiffs:otherDiffs];
	
	NSArray *otherResult = [dmp patch_apply:otherPatches toString:oldValue];
	NSString *otherString = [otherResult objectAtIndex:0];
	NSArray *combinedResult = [dmp patch_apply:thisPatches toString:otherString];
	NSString *combinedString = [combinedResult objectAtIndex:0];
	
	NSMutableArray *finalDiffs = [dmp diff_mainOfOldString:otherString andNewString:combinedString];// [dmp diff_fromDeltaWithText:otherString andDelta:combinedString error:&error];
	if ([finalDiffs count] > 2)
		[dmp diff_cleanupEfficiency:finalDiffs];
	
	if ([finalDiffs count] > 0) {
		NSString *delta = [dmp diff_toDelta:finalDiffs];
		return [NSDictionary dictionaryWithObjectsAndKeys:
				OP_STRING, OP_OP,
				delta, OP_VALUE, nil];
	}
	
	return [NSDictionary dictionary];
}

@end
