#import <XCTest/XCTest.h>
#import "ServiceRemoteREST.h"
#import "WordPressComApi.h"

@interface ServiceRemoteRESTTests : XCTestCase
@end

@implementation ServiceRemoteRESTTests

#pragma mark - Initialization tests

- (void)testThatInitThrowsAssertionFailureWithoutApi
{
    XCTAssertThrows([[ServiceRemoteREST alloc] initWithApi:nil]);
}

- (void)testRegularInitialization
{
    WordPressComApi *api = [[WordPressComApi alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    ServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[ServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertTrue([service isKindOfClass:[ServiceRemoteREST class]]);
    XCTAssertTrue(service.api == api);
}

@end
