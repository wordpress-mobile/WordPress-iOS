#import <XCTest/XCTest.h>
#import "ServiceRemoteWordPressComREST.h"

@interface ServiceRemoteWordPressComRESTTests : XCTestCase
@end

@implementation ServiceRemoteWordPressComRESTTests

#pragma mark - Initialization tests

- (void)testThatInitThrowsAssertionFailureWithoutApi
{
    XCTAssertThrows([[ServiceRemoteWordPressComREST alloc] initWithWordPressComRestApi:nil]);
}

- (void)testRegularInitialization
{
    WordPressComRestApi *api = [[WordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    ServiceRemoteWordPressComREST *service = nil;
    
    XCTAssertNoThrow(service = [[ServiceRemoteWordPressComREST alloc] initWithWordPressComRestApi:api]);
    XCTAssertTrue([service isKindOfClass:[ServiceRemoteWordPressComREST class]]);
    XCTAssertTrue(service.wordPressComRestApi == api);
}

@end
