//
//  SPMemberJSONTests.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 2/18/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SPMemberJSON.h"


/*
	References:
	-	https://github.com/Simperium/jsondiff/blob/master/src/jsondiff.coffee
	-	https://github.com/apokalyptik/go-jsondiff/blob/master/assertions.json
	-	Many thanks to Demitrious Kelly for his help!
 */

@interface SPMemberJSONTests : XCTestCase
@property (nonatomic, strong) SPMemberJSON *jsonMember;
@end

@implementation SPMemberJSONTests

- (void)setUp {
	self.jsonMember = [SPMemberJSON new];
}

- (void)testListInsertOperation {
	NSDictionary *local		= @{  };
	
	NSDictionary *diff		= @{
									@"body" :	@{
													@"o" : @"+",
													@"v" : @{
																@"something" : @(31337)
															}
												}
							  };
									
	NSDictionary *expected	= @{
									@"body" :	@{
													@"something" : @(31337)
												}
								};

	NSDictionary *output = [self.jsonMember applyDiff:local otherValue:diff];
	XCTAssertEqualObjects(output, expected, @"Error applying ListInsertion Diff");
}

- (void)testListDeleteOperation {
	NSDictionary *local		= @{
								@"body" :	@{
												@"something" : @(31337)
											}
								};
	
	NSDictionary *diff		= @{
								@"body" :	@{
												@"o" : @"-",
												@"v" : @{
															@"something" : @(31337)
														}
											}
								};
	
	NSDictionary *expected	= @{ };
	
	NSDictionary *output = [self.jsonMember applyDiff:local otherValue:diff];
	XCTAssertEqualObjects(output, expected, @"Error applying ListInsertion Diff");
}

- (void)testListReplaceOperation {
	NSDictionary *local		= @{
								@"body" :	@{
												@"something" : @(31337)
											}
								};
	
	NSDictionary *diff		= @{
								@"body" :	@{
												@"o" : @"+",
												@"v" : @{
															@"something-else" : @(42)
														}
											}
								};
	
	NSDictionary *expected	= @{
								@"body" :	@{
												@"something-else" : @(42)
											}
								};
	
	NSDictionary *output = [self.jsonMember applyDiff:local otherValue:diff];
	XCTAssertEqualObjects(output, expected, @"Error applying ListInsertion Diff");
}

- (void)testObjectOperation {
	NSDictionary *local		= @{
								@"body" :	@{
												@"a" : @"b"
											}
								};
	
	NSDictionary *diff		= @{
								@"body" :	@{
										@"o" : @"O",
										@"v" : @{
													@"e" : @{
																@"o" : @"+",
																@"v" : @"d"
															}
												}
										}
								};
	
	NSDictionary *expected	= @{
								@"body" :	@{
												@"a" : @"b",
												@"e" : @"d"
											}
								};
	
	NSDictionary *output = [self.jsonMember applyDiff:local otherValue:diff];
	XCTAssertEqualObjects(output, expected, @"Error applying ListInsertion Diff");
}

@end
