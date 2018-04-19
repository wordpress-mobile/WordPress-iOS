#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
@import WordPressKit;

@interface ServiceRemoteWordPressComRESTTests : XCTestCase
@end

@implementation ServiceRemoteWordPressComRESTTests

#pragma mark - Initialization tests

- (void)testRegularInitialization
{
    WordPressComRestApi *api = [[WordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    ServiceRemoteWordPressComREST *service = nil;
    
    XCTAssertNoThrow(service = [[ServiceRemoteWordPressComREST alloc] initWithWordPressComRestApi:api]);
    XCTAssertTrue([service isKindOfClass:[ServiceRemoteWordPressComREST class]]);
    XCTAssertTrue(service.wordPressComRestApi == api);
}

@end
