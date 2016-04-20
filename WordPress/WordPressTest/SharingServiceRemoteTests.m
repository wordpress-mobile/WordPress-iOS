#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "Blog.h"
#import "ServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "WordPressTests-Swift.h"
#import "WordPress-Swift.h"

@interface SharingServiceRemoteTests : XCTestCase

@end


@implementation SharingServiceRemoteTests

#pragma mark - Synchronizing connections for a blog

- (void)testGetPublicizeServices
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    SharingServiceRemote *service = nil;

    NSString *url = @"v1.1/meta/external-services";
    NSDictionary *params = @{@"type":@"publicize"};

    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isEqual:params]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithApi:api]);

    [service getPublicizeServices:^(NSArray *services) {} failure:^(NSError *error) {}];
}


- (void)testGetKeyringServices
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    SharingServiceRemote *service = nil;

    NSString *url = @"v1.1/me/keyring-connections";

    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithApi:api]);

    [service getKeyringConnections:^(NSArray *connections) {} failure:^(NSError *error) {}];
}


- (void)testGetPublicizeConnections
{
    NSNumber *mockID = @10;

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    SharingServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/publicize-connections", mockID];

    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithApi:api]);

    [service getPublicizeConnections:mockID
                             success:^(NSArray *connections) {}
                             failure:^(NSError *error) {}];
}


- (void)testCreatePublicizeConnection
{
    NSNumber *mockID = @10;

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    SharingServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/publicize-connections/new", mockID];

    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNotNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithApi:api]);

    [service createPublicizeConnection:mockID
                   keyringConnectionID:mockID
                        externalUserID:nil
                               success:^(RemotePublicizeConnection *remotePubConn) {}
                               failure:^(NSError *error) {}];

}


- (void)testDeletePublicizeConnection
{
    NSNumber *mockID = @10;

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    SharingServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/publicize-connections/%@/delete", mockID, mockID];

    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithApi:api]);

    [service deletePublicizeConnection:mockID connectionID:mockID success:^{} failure:^(NSError *error) {}];
}



- (void)testGetSharingButtonsForSite
{
    NSNumber *mockID = @10;

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    SharingServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/sharing-buttons", mockID];

    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithApi:api]);

    [service getSharingButtonsForSite:mockID
                             success:^(NSArray *buttons) {}
                              failure:^(NSError *error) {}];
}


- (void)testUpdateSharingButtonsForSite
{
    NSNumber *mockID = @10;

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    SharingServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/sharing-buttons", mockID];
    NSArray *buttons = [NSArray array];

    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNotNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[SharingServiceRemote alloc] initWithApi:api]);

    [service updateSharingButtonsForSite:mockID
                          sharingButtons:buttons
                                 success:^(NSArray *buttons){}
                                 failure:^(NSError *error) {}];
}


@end
