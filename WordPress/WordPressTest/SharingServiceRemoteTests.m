#import <XCTest/XCTest.h>
#import "Blog.h"
#import "WordPressTests-Swift.h"

@interface SharingServiceRemoteTests : XCTestCase

@end


@implementation SharingServiceRemoteTests

#pragma mark - Synchronizing connections for a blog

- (void)testGetPublicizeServices
{
    MockWordPressComRestApi *api = [[MockWordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    SharingServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    [service getPublicizeServices:^(NSArray *services) {} failure:^(NSError *error) {}];

    XCTAssertTrue([api getMethodCalled], @"Method was not called");
    XCTAssertEqualObjects([api URLStringPassedIn], @"v1.1/meta/external-services", @"Incorrect URL passed in");
    NSDictionary * parameters = [api parametersPassedIn];
    XCTAssertEqualObjects(parameters[@"type"], @"publicize", @"incorrect type parameter");
}


- (void)testGetKeyringServices
{
    MockWordPressComRestApi *api = [[MockWordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    SharingServiceRemote *service = nil;

    NSString *url = @"v1.1/me/keyring-connections";

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    [service getKeyringConnections:^(NSArray *connections) {} failure:^(NSError *error) {}];

    XCTAssertTrue([api getMethodCalled], @"Method was not called");
    XCTAssertEqualObjects([api URLStringPassedIn], url, @"Incorrect URL passed in");
}


- (void)testGetPublicizeConnections
{
    NSNumber *mockID = @10;

    MockWordPressComRestApi *api = [[MockWordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    SharingServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/publicize-connections", mockID];

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    [service getPublicizeConnections:mockID
                             success:^(NSArray *connections) {}
                             failure:^(NSError *error) {}];

    XCTAssertTrue([api getMethodCalled], @"Method was not called");
    XCTAssertEqualObjects([api URLStringPassedIn], url, @"Incorrect URL passed in");
}


- (void)testCreatePublicizeConnection
{
    NSNumber *mockID = @10;

    MockWordPressComRestApi *api = [[MockWordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    SharingServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/publicize-connections/new", mockID];

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    [service createPublicizeConnection:mockID
                   keyringConnectionID:mockID
                        externalUserID:nil
                               success:^(RemotePublicizeConnection *remotePubConn) {}
                               failure:^(NSError *error) {}];
    XCTAssertTrue([api postMethodCalled], @"Method was not called");
    XCTAssertEqualObjects([api URLStringPassedIn], url, @"Incorrect URL passed in");
}


- (void)testDeletePublicizeConnection
{
    NSNumber *mockID = @10;

    MockWordPressComRestApi *api = [[MockWordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    SharingServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/publicize-connections/%@/delete", mockID, mockID];

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    [service deletePublicizeConnection:mockID connectionID:mockID success:^{} failure:^(NSError *error) {}];

    XCTAssertTrue([api postMethodCalled], @"Method was not called");
    XCTAssertEqualObjects([api URLStringPassedIn], url, @"Incorrect URL passed in");
}



- (void)testGetSharingButtonsForSite
{
    NSNumber *mockID = @10;

    MockWordPressComRestApi *api = [[MockWordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    SharingServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/sharing-buttons", mockID];

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    [service getSharingButtonsForSite:mockID
                             success:^(NSArray *buttons) {}
                              failure:^(NSError *error) {}];

    XCTAssertTrue([api getMethodCalled], @"Method was not called");
    XCTAssertEqualObjects([api URLStringPassedIn], url, @"Incorrect URL passed in");
}


- (void)testUpdateSharingButtonsForSite
{
    NSNumber *mockID = @10;

    MockWordPressComRestApi *api = [[MockWordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    SharingServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/sharing-buttons", mockID];
    NSArray *buttons = [NSArray array];

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    [service updateSharingButtonsForSite:mockID
                          sharingButtons:buttons
                                 success:^(NSArray *buttons){}
                                 failure:^(NSError *error) {}];

    XCTAssertTrue([api postMethodCalled], @"Method was not called");
    XCTAssertEqualObjects([api URLStringPassedIn], url, @"Incorrect URL passed in");
}


@end
