#import <XCTest/XCTest.h>
#import "NSURL+Util.h"

@interface NSURLUtilTest : XCTestCase
@end

@implementation NSURLUtilTest

- (void)testIsUnknownGravatarUrlMatchesURLWithSubdomainAndQueryParameters
{
    NSURL *url = [NSURL URLWithString:@"https://0.gravatar.com/avatar/ad516503a11cd5ca435acc9bb6523536?s=256&r=G"];
    XCTAssertTrue(url.isUnknownGravatarUrl);
}

- (void)testIsUnknownGravatarUrlMatchesURLWithoutSubdomains
{
    NSURL *url = [NSURL URLWithString:@"https://0.gravatar.com/avatar/ad516503a11cd5ca435acc9bb6523536"];
    XCTAssertTrue(url.isUnknownGravatarUrl);
}

- (void)testIsUnknownGravatarUrlMatchesURLWithHttpSchema
{
    NSURL *url = [NSURL URLWithString:@"http://0.gravatar.com/avatar/ad516503a11cd5ca435acc9bb6523536"];
    XCTAssertTrue(url.isUnknownGravatarUrl);
}

- (void)testIsUnknownGravatarUrlPassesThroughAnIncorrectURL
{
    NSURL *url = [NSURL URLWithString:@"http://0.gravatar.com/ad516503a11cd5ca435acc9bb6523536"];
    XCTAssertFalse(url.isUnknownGravatarUrl);
}

@end
