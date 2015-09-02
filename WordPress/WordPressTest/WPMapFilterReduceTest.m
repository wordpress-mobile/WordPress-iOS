//
//  WPMapFilterReduceTest.m
//  WordPress
//
//  Created by Jorge Bernal on 14/8/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WPMapFilterReduce.h"

@interface WPMapFilterReduceTest : XCTestCase

@end

@implementation WPMapFilterReduceTest

- (void)testMap {
    NSArray *test = @[ @1, @2, @10 ];
    NSArray *result = [test wp_map:^id(NSNumber *obj) {
        return @( [obj integerValue] * 10 );
    }];
    NSArray *expected = @[ @10, @20, @100 ];
    XCTAssertEqualObjects(expected, result);
}

- (void)testMapDoesntCrashWithNilValues {
    NSArray *test = @[ @1, @2, @10 ];
    NSArray *result = [test wp_map:^id(NSNumber *obj) {
        if ([obj integerValue] > 5) {
            return nil;
        }
        return @( [obj integerValue] * 10 );
    }];
    NSArray *expected = @[ @10, @20 ];
    XCTAssertEqualObjects(expected, result);
}

- (void)testMapPerformance {
    NSMutableArray *testArray = [NSMutableArray arrayWithCapacity:1000];
    for (int i = 0; i < 10000; i++) {
        [testArray addObject:@(i)];
    };

    [self measureBlock:^{
        [testArray wp_map:^id(id obj) {
            return @( [obj integerValue] * 10 );
        }];
    }];
}

- (void)testFilter
{
    NSArray *test = @[ @1, @2, @10 ];
    NSArray *result = [test wp_filter:^BOOL(NSNumber *obj) {
        return [obj integerValue] > 5;
    }];
    NSArray *expected = @[ @10 ];
    XCTAssertEqualObjects(expected, result);
}

- (void)testFilterPerformance {
    NSMutableArray *testArray = [NSMutableArray arrayWithCapacity:1000];
    for (int i = 0; i < 10000; i++) {
        [testArray addObject:@(i)];
    };

    [self measureBlock:^{
        [testArray wp_filter:^BOOL(id obj) {
            return [obj integerValue] % 10 == 5;
        }];
    }];
}

- (void)testReduce
{
    NSArray *test = @[ @1, @2, @3, @4, @5, @6, @7, @8, @9, @10 ];
    NSNumber *result = [test wp_reduce:^id(id accumulator, id obj) {
        return @([accumulator longLongValue] + [obj longLongValue]);
    } withInitialValue:@0];
    NSNumber *expected = @55;
    XCTAssertEqualObjects(expected, result);
}

@end
