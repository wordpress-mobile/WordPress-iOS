//
//  SPMemberText.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPMemberText.h"
#import "DiffMatchPatch.h"
#import "DiffMatchPatch+Simperium.h"



@interface SPMemberText ()
@property (nonatomic, strong) DiffMatchPatch *dmp;
@end


@implementation SPMemberText

- (id)initFromDictionary:(NSDictionary *)dict
{
    if (self = [super initFromDictionary:dict]) {
        _dmp = [[DiffMatchPatch alloc] init];
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
	NSMutableArray *diffList = [self.dmp diff_mainOfOldString:thisValue andNewString:otherValue];
	if (diffList.count > 2) {
		[self.dmp diff_cleanupSemantic:diffList];
		[self.dmp diff_cleanupEfficiency:diffList];
	}
	
	if (diffList.count > 0 && [self.dmp diff_levenshtein:diffList] != 0) {
		// Construct the patch delta and return it as a change operation
		NSString *delta = [self.dmp diff_toDelta:diffList];
        return @{
            OP_OP       : OP_STRING,
            OP_VALUE    : delta
        };
	}
    
	// No difference
	return [NSDictionary dictionary];
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue error:(NSError **)error {
    // Special case if there was no previous value
    // REMOVED THIS: causes an actual diff (e.g. "+H") to be entered as the new value
    // if ([thisValue length] == 0)
    //    return otherValue;
    
	NSMutableArray *diffs   = [self.dmp diff_fromDeltaWithText:thisValue andDelta:otherValue error:error];
	NSMutableArray *patches = [self.dmp patch_makeFromOldString:thisValue andDiffs:diffs];
	NSArray *result         = [self.dmp patch_apply:patches toString:thisValue];

	return [result firstObject];
}

- (NSDictionary *)transform:(id)thisValue otherValue:(id)otherValue oldValue:(id)oldValue error:(NSError **)error {
	// Calculate the delta from the Ghost to the Local + Remote values. Treat any error here as fatal
	NSMutableArray *thisDiffs       = [self.dmp diff_fromDeltaWithText:oldValue andDelta:thisValue error:error];
	NSMutableArray *otherDiffs      = [self.dmp diff_fromDeltaWithText:oldValue andDelta:otherValue error:error];
    if (error && *error) {
        return @{ };
    }
    
    // Attempt to apply those two patches
	NSMutableArray *thisPatches     = [self.dmp patch_makeFromOldString:oldValue andDiffs:thisDiffs];
	NSMutableArray *otherPatches    = [self.dmp patch_makeFromOldString:oldValue andDiffs:otherDiffs];
	
    NSError *internalError          = nil;
	NSArray *otherResult            = [self.dmp patch_apply:otherPatches toString:oldValue error:&internalError];
	NSString *otherString           = [otherResult firstObject];
    
	NSArray *combinedResult         = [self.dmp patch_apply:thisPatches toString:otherString error:&internalError];
	NSString *combinedString        = [combinedResult firstObject];
    
    // If the rebase fails, fallback to the Local State
    if (internalError) {
        combinedResult              = [self.dmp patch_apply:thisPatches toString:oldValue error:error];
        combinedString              = [combinedResult firstObject];
    }
	
	NSMutableArray *finalDiffs      = [self.dmp diff_mainOfOldString:otherString andNewString:combinedString];
	if (finalDiffs.count > 2) {
		[self.dmp diff_cleanupEfficiency:finalDiffs];
	}
    
	if (finalDiffs.count > 0) {
        NSString *delta = [self.dmp diff_toDelta:finalDiffs];
        
        return @{
            OP_OP       : OP_STRING,
            OP_VALUE    : delta
        };
	}
	
	return @{ };
}

@end
