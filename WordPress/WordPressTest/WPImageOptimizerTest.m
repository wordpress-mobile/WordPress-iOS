#import <XCTest/XCTest.h>
#import "WPImageOptimizer.h"
#import "WPImageOptimizer+Private.h"

@interface WPImageOptimizerTest : XCTestCase

@end

@implementation WPImageOptimizerTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSizeWithinLimits
{
    WPImageOptimizer *optimizer = [WPImageOptimizer new];
    CGSize fittingSize = CGSizeMake(2048, 2048);
    
    CGSize original = CGSizeMake(1024, 512);
    CGSize expected = CGSizeMake(1024, 512);
    CGSize resized = [optimizer sizeForOriginalSize:original fittingSize:fittingSize];
    XCTAssertEqual(resized.width, expected.width, @"Images shouldn't scale up");
    XCTAssertEqual(resized.height, expected.height, @"Images shouldn't scale up");

    original = CGSizeMake(4000, 3000);
    expected = CGSizeMake(2048, 1536);

    resized = [optimizer sizeForOriginalSize:original fittingSize:fittingSize];
    XCTAssertEqual(resized.width, expected.width);
    XCTAssertEqual(resized.height, expected.height);

    original = CGSizeMake(3000, 4000);
    expected = CGSizeMake(1536, 2048);

    resized = [optimizer sizeForOriginalSize:original fittingSize:fittingSize];
    XCTAssertEqual(resized.width, expected.width);
    XCTAssertEqual(resized.height, expected.height);

    original = CGSizeMake(4000, 4000);
    expected = CGSizeMake(2048, 2048);

    resized = [optimizer sizeForOriginalSize:original fittingSize:fittingSize];
    XCTAssertEqual(resized.width, expected.width);
    XCTAssertEqual(resized.height, expected.height);

    original = CGSizeMake(2049, 2048);
    expected = CGSizeMake(2048, 2047);

    resized = [optimizer sizeForOriginalSize:original fittingSize:fittingSize];
    XCTAssertEqual(resized.width, expected.width);
    XCTAssertEqual(round(resized.height), round(expected.height));
}

@end
