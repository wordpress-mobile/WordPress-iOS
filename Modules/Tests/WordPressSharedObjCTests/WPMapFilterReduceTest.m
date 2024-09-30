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

@end
