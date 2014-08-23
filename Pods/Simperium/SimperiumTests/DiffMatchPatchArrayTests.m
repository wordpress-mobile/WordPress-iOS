//
//  DiffMatchPatchArrayTests.m
//  Simperium
//
//  Created by Andrew Mackenzie-Ross on 19/07/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DiffMatchPatch.h"
#import "NSArray+Simperium.h"


@interface DiffMatchPatchArrayTests : XCTestCase
@property (nonatomic, strong) DiffMatchPatch *dmp;
@end


@implementation DiffMatchPatchArrayTests

- (void)setUp
{
	self.dmp = [[DiffMatchPatch alloc] init];
}

- (void)testDiffAndApply
{
	NSDictionary *testsOneElementOperationPairs = @{
		@[ @"a" ]: @[  @1 ] , // replace one element
		@[ @"a" ]: @[], // remove element
		@[]: @[ @"a" ], // add element to empty array
		@[ @"a" ]: @[ @"a", @1 ], // add element to existing
		@[ @"a", @1 ]: @[ @"a" ], // remove last element
		@[ @"a", @1 ]: @[ @1 ], // remove first element
	};
	
	NSDictionary *testTwoElementOperationsPairs = @{
		@[ @"a", @1 ]: @[ @YES, @1 ],		// replace first element
		@[ @"a", @1 ]: @[ @"a" , @2 ],		// replace last element
		@[ @"a", @1 ]: @[ @1, @"a" ],		// inverse two elements
		@[ @"a", @1 ]: @[ @"b", @2 ],		// two new elements
		@[ @"a", @1 ]: @[ @"b", @"a", @1 ], // insert new element at head
		@[ @"b", @"a", @1 ]: @[ @"a", @1 ], // remove element from head
		@[ @"a", @1 ]: @[ @"a", @"b", @1 ], // insert element in midde
		@[ @"a", @"b", @1 ]: @[ @"a", @1 ], // remove element from middle
		@[ @"a", @1 ]: @[ @"a", @1, @"b" ], // insert element at tail
		@[ @"a", @1, @"b" ]: @[ @"a", @1 ], // remove element from tail
		@[] : @[ @"a", @1 ],				// insert two elements
		@[ @"a", @1 ]: @[]					// remove two elements
   };
	
	NSDictionary *testThreeElementOperationsPairs = @{
		@[ @"a", @1 ]: @[ @YES, @1 ], // replace first element
		@[ @"a", @1, [NSNull null] ]: @[ @"a" , @2, @[ @YES, @"NO", @{ @"something" : @"with objects" } ] ], // replace last element
		@[ @"a", @1, [NSNull null] ]: @[ @1, @"a", [NSNull null] ], // inverse two elements
	};
	
	[testsOneElementOperationPairs enumerateKeysAndObjectsUsingBlock:^(id array1, id array2, BOOL *stop) {
		XCTAssertEqualObjects(array1, [self createDiffAndApplyDiffArray1:array2 array2:array1], @"replace diff 1 element");
	}];
	[testTwoElementOperationsPairs enumerateKeysAndObjectsUsingBlock:^(id array1, id array2, BOOL *stop) {
		XCTAssertEqualObjects(array1, [self createDiffAndApplyDiffArray1:array2 array2:array1], @"replace diff 1 element");
	}];
	
	[testThreeElementOperationsPairs enumerateKeysAndObjectsUsingBlock:^(id array1, id array2, BOOL *stop) {
		XCTAssertEqualObjects(array1, [self createDiffAndApplyDiffArray1:array2 array2:array1], @"replace diff 1 element");
	}];
}

- (NSArray *)createDiffAndApplyDiffArray1:(NSArray *)array1 array2:(NSArray *)array2
{
	NSString *delta = [array1 sp_diffDeltaWithArray:array2 diffMatchPatch:self.dmp];
	return [array1 sp_arrayByApplyingDiffDelta:delta diffMatchPatch:self.dmp];
}

@end
