#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface ProgressTest : XCTestCase

@end

@implementation ProgressTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testChildProgress {
    // This is an example of a functional test case.
    NSProgress * progress = [NSProgress progressWithTotalUnitCount:1];
    [progress becomeCurrentWithPendingUnitCount:1];
    NSProgress * childProgress = [NSProgress progressWithTotalUnitCount:10];
    [progress resignCurrent];
    
    XCTestExpectation * expectationPartial = [self expectationWithDescription:@"Wait For Partial Progress"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        childProgress.completedUnitCount+=8;
        [expectationPartial fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
    XCTAssertEqual(0, progress.completedUnitCount);
    
    XCTestExpectation * expectationFull = [self expectationWithDescription:@"Wait For Full Progress"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        childProgress.completedUnitCount+=2;
        [expectationFull fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
    XCTAssertEqual(1, progress.completedUnitCount);
}

@end
