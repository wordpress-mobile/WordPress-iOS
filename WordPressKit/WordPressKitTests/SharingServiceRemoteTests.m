#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "WordPressKitTests-Swift.h"
@import WordPressKit;

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

    NSString *url = [service pathForEndpoint:@"meta/external-services"
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    XCTAssertEqualObjects([api URLStringPassedIn], url, @"Incorrect URL passed in");
    NSDictionary * parameters = [api parametersPassedIn];
    XCTAssertEqualObjects(parameters[@"type"], @"publicize", @"incorrect type parameter");
}


- (void)testGetKeyringServices
{
    MockWordPressComRestApi *api = [[MockWordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    SharingServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *url = [service pathForEndpoint:@"me/keyring-connections"
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [service getKeyringConnections:^(NSArray *connections) {} failure:^(NSError *error) {}];

    XCTAssertTrue([api getMethodCalled], @"Method was not called");
    XCTAssertEqualObjects([api URLStringPassedIn], url, @"Incorrect URL passed in");
}


- (void)testGetPublicizeConnections
{
    NSNumber *mockID = @10;

    MockWordPressComRestApi *api = [[MockWordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    SharingServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/publicize-connections", mockID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

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

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/publicize-connections/new", mockID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

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

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/publicize-connections/%@/delete", mockID, mockID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [service deletePublicizeConnection:mockID connectionID:mockID success:^{} failure:^(NSError *error) {}];

    XCTAssertTrue([api postMethodCalled], @"Method was not called");
    XCTAssertEqualObjects([api URLStringPassedIn], url, @"Incorrect URL passed in");
}



- (void)testGetSharingButtonsForSite
{
    NSNumber *mockID = @10;

    MockWordPressComRestApi *api = [[MockWordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    SharingServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/sharing-buttons", mockID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

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

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/sharing-buttons", mockID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    NSArray *buttons = [NSArray array];

    [service updateSharingButtonsForSite:mockID
                          sharingButtons:buttons
                                 success:^(NSArray *buttons){}
                                 failure:^(NSError *error) {}];

    XCTAssertTrue([api postMethodCalled], @"Method was not called");
    XCTAssertEqualObjects([api URLStringPassedIn], url, @"Incorrect URL passed in");
}


@end
