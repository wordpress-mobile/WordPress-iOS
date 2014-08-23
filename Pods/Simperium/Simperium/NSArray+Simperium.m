//
//  NSArray+Simperium.m
//  Simperium
//
//  Created by Andrew Mackenzie-Ross on 19/07/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "NSArray+Simperium.h"
#import "SPMember.h"
#import "DiffMatchPatch.h"
#import "JSONKit+Simperium.h"


@implementation NSArray (Simperium)

#pragma mark - List Diffs With Diff Match Patch

- (NSString *)sp_diffDeltaWithArray:(NSArray *)obj diffMatchPatch:(DiffMatchPatch *)dmp
{
	NSParameterAssert(obj); NSParameterAssert(dmp);
	return [self sp_deltaWithArray:obj diffMatchPatch:dmp];
}

- (NSArray *)sp_arrayByApplyingDiffDelta:(NSString *)delta diffMatchPatch:(DiffMatchPatch *)dmp
{
	NSParameterAssert(delta); NSParameterAssert(dmp);
	
	NSString *newLineSeparatedJSONString = [self sp_newLineSeparatedJSONString];
	
	NSError __autoreleasing *error = nil;
	NSMutableArray *diffs = [dmp diff_fromDeltaWithText:newLineSeparatedJSONString andDelta:delta error:&error];

	if (error) {
		[NSException raise:NSInternalInconsistencyException format:@"Simperium: Error creating diff from delta with text %@ and delta %@ due to error %@ in %s.", newLineSeparatedJSONString, delta, error, __PRETTY_FUNCTION__];
	}

	NSMutableArray *patches = [dmp patch_makeFromDiffs:diffs];
	NSString *updatedNewlineSeparatedString = [dmp patch_apply:patches toString:newLineSeparatedJSONString][0];
	
	return [NSArray sp_arrayFromNewLineSeparatedJSONString:updatedNewlineSeparatedString];
}

- (NSString *)sp_transformDelta:(NSString *)delta onto:(NSString *)otherDelta diffMatchPatch:(DiffMatchPatch *)dmp
{
	NSParameterAssert(delta); NSParameterAssert(otherDelta); NSParameterAssert(dmp);
	NSString *sourceText = [self sp_newLineSeparatedJSONString];
	
	NSError __autoreleasing *error = nil;
	NSMutableArray *diff1Patches = [dmp diff_fromDeltaWithText:sourceText andDelta:delta error:&error];
	if (error) [NSException raise:NSInternalInconsistencyException format:@"Simperium: Error creating diff from delta with text %@ and delta %@ due to error %@ in %s.", sourceText, delta, error, __PRETTY_FUNCTION__];
		NSMutableArray *diff2Patches = [dmp diff_fromDeltaWithText:sourceText andDelta:otherDelta error:&error];
	if (error) [NSException raise:NSInternalInconsistencyException format:@"Simperium: Error creating diff from delta with text %@ and delta %@ due to error %@ in %s.", sourceText, otherDelta, error, __PRETTY_FUNCTION__];
	
	NSString *diff2Text = [dmp patch_apply:diff2Patches toString:sourceText][0];
	NSString *diff2And1Text = [dmp patch_apply:diff1Patches toString:diff2Text][0];
	
	if ([diff2And1Text isEqualToString:diff2Text]) return @""; // no-op diff
	
	NSMutableArray *diffs = [dmp diff_lineModeFromOldString:diff2Text andNewString:diff2And1Text deadline:0];
	
	return [dmp diff_toDelta:diffs];
}


- (NSString *)sp_deltaWithArray:(NSArray *)obj diffMatchPatch:(DiffMatchPatch *)dmp
{
	NSParameterAssert(obj); NSParameterAssert(dmp);
	
	NSString *nljs1 = [self sp_newLineSeparatedJSONString];
	NSString *nljs2 = [obj sp_newLineSeparatedJSONString];
	

	NSArray *b = [dmp diff_linesToCharsForFirstString:nljs1 andSecondString:nljs2];
	NSString *text1 = (NSString *)[b objectAtIndex:0];
	NSString *text2 = (NSString *)[b objectAtIndex:1];
	NSMutableArray *linearray = (NSMutableArray *)[b objectAtIndex:2];
	
	NSMutableArray *diffs = nil;
	@autoreleasepool {
		diffs = [dmp diff_mainOfOldString:text1 andNewString:text2 checkLines:NO deadline:0];
	}
	
	// Convert the diff back to original text.
	[dmp diff_chars:diffs toLines:linearray];
	// Eliminate freak matches (e.g. blank lines)
	[dmp diff_cleanupSemantic:diffs];
	
	// Removing "-0	" as this is a no-op operations that crashes the apply patch method.
	return [[dmp diff_toDelta:diffs] stringByReplacingOccurrencesOfString:@"-0	" withString:@""];
}

- (NSString *)sp_newLineSeparatedJSONString
{
	// Create a new line separated list of JSON objects in an array.
	// e.g.
	// { "a" : 1, "c" : "3" }\n{ "b" : 2 }\n
	//
	NSMutableString *JSONString = [[NSMutableString alloc] init];
	for (id object in self) {
		if (object == (id)kCFBooleanTrue) {
			[JSONString appendString:@"true\n"];
		} else if (object == (id)kCFBooleanFalse) {
			[JSONString appendString:@"false\n"];
		} else if ([object isKindOfClass:[NSNumber class]]) {
			[JSONString appendFormat:@"%@\n",object];
		} else if ([object isKindOfClass:[NSString class]]) {
			[JSONString appendFormat:@"\"%@\"\n",object];
		} else if (object == [NSNull null]) {
			[JSONString appendString:@"null\n"];
		} else if ([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]]) {
			[JSONString appendFormat:@"%@\n",[[object sp_JSONString] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
		} else {
			[NSException raise:NSInternalInconsistencyException format:@"Simperium: Cannot create diff match patch with non-json object %@ in %s",object,__PRETTY_FUNCTION__];
		}
	}
	
	// Remove final \n character from string
	if ([JSONString isEqualToString:@""]) return JSONString;
	return [JSONString substringToIndex:[JSONString length] - 1];
}

+ (NSArray *)sp_arrayFromNewLineSeparatedJSONString:(NSString *)string
{
	NSParameterAssert(string);
	
	NSArray *JSONStrings = [string componentsSeparatedByString:@"\n"];
	// Remove any lines with nothing on them.
	JSONStrings = [JSONStrings filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		return ![evaluatedObject isEqual:@""];
	}]];
	NSString *JSONArrayString = [NSString stringWithFormat:@"[ %@ ]", [JSONStrings componentsJoinedByString:@", "]];
	return [JSONArrayString sp_objectFromJSONString];
}



#pragma mark - List Diff with Operations

// TODO: Implement?
//
//- (NSArray *)sp_arrayByApplyingDiff:(NSDictionary *)diff
//{
//	NSMutableArray *array = [self mutableCopy];
//	
//	NSArray *indexes = [[diff allKeys] sortedArrayUsingSelector:@selector(compare:)];
//	NSMutableIndexSet *indexesToReplace = [[NSMutableIndexSet alloc] init];
//	NSMutableArray *replacementObjects = [[NSMutableArray alloc] init];
//	NSMutableIndexSet *indexesToRemove = [[NSMutableIndexSet alloc] init];
//	NSMutableIndexSet *indexesToInsert = [[NSMutableIndexSet alloc] init];
//	NSMutableArray *insertedObjects = [[NSMutableArray alloc] init];
//	for (NSNumber *index in indexes) {
//		NSDictionary *elementDiff = [diff objectForKey:index];
//		
//		NSString *operation = [elementDiff objectForKey:OP_OP];
//		if ([operation isEqualToString:OP_REPLACE]) {
//			[replacementObjects addObject:[elementDiff objectForKey:OP_VALUE]];
//			[indexesToReplace addIndex:[index integerValue]];
//		} else if ([operation isEqualToString:OP_LIST_DELETE]) {
//			[indexesToRemove addIndex:[index integerValue]];
//		} else if ([operation isEqualToString:OP_LIST_INSERT]) {
//			[insertedObjects addObject:[elementDiff objectForKey:OP_VALUE]];
//			[indexesToInsert addIndex:[index integerValue]];
//		} else {
//			NSAssert(NO, @"Diff operation %@ is not supported within lists.", operation);
//		}
//	}
//	
//	[array replaceObjectsAtIndexes:indexesToReplace withObjects:replacementObjects];
//	[array removeObjectsAtIndexes:indexesToRemove];
//	[array insertObjects:insertedObjects atIndexes:indexesToInsert];
//	
//	return array;
//}
//
//- (NSDictionary *)sp_diffWithArray:(NSArray *)obj2
//{
//	if ([self isEqualToArray:obj2]) return @{};
//	NSArray *obj1 = self;
//	
//	NSMutableDictionary *diffs = [[NSMutableDictionary alloc] init];
//	
//	NSInteger prefixCount = [obj1 sp_countOfObjectsCommonWithArray:obj2 options:0];
//	obj1 = [obj1 subarrayWithRange:NSMakeRange(prefixCount, [obj1 count] - prefixCount)];
//	obj2 = [obj2 subarrayWithRange:NSMakeRange(prefixCount, [obj2 count] - prefixCount)];
//	
//	NSInteger suffixCount = [obj1 sp_countOfObjectsCommonWithArray:obj2 options:NSEnumerationReverse];
//	obj1 = [obj1 subarrayWithRange:NSMakeRange(0, [obj1 count] - suffixCount)];
//	obj2 = [obj2 subarrayWithRange:NSMakeRange(0, [obj2 count] - suffixCount)];
//	
//	NSInteger obj1Count = [obj1 count];
//	NSInteger obj2Count = [obj2 count];
//	for (int i = 0; i < MAX(obj1Count, obj2Count); i++) {
//		if (i < obj1Count && i < obj2Count) {
//			if ([obj1[i] isEqual:obj2[i]] == NO) {
//				diffs[@(i + prefixCount)] = @{ OP_OP: OP_REPLACE, OP_VALUE: obj2[i] };
//			}
//		} else if (i < obj1Count) {
//			diffs[@(i + prefixCount)] = @{ OP_OP: OP_LIST_DELETE };
//		} else if (i < obj2Count) {
//			diffs[@(i + prefixCount)] = @{ OP_OP: OP_LIST_INSERT, OP_VALUE: obj2[i] };
//		}
//	}
//	
//	return diffs;
//}
//
//
//
//- (NSInteger)sp_countOfObjectsCommonWithArray:(NSArray *)b options:(NSEnumerationOptions)options
//{
//	NSAssert(options ^ NSEnumerationConcurrent, @"%s doesn't support NSEnumerationConcurrent",__PRETTY_FUNCTION__);
//	__block NSInteger count = 0;
//	NSArray *a = self;
//	NSInteger shift = (options & NSEnumerationReverse) ? [b count] - [a count] : 0;
//	[self enumerateObjectsWithOptions:options usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//		NSInteger idxIntoB = idx + shift;
//		if (idxIntoB >= [b count] || idxIntoB < 0 || ![obj isEqual:b[idxIntoB]]) {
//			*stop = YES;
//		} else {
//			count++;
//		}
//	}];
//	
//	return count;
//}



@end
