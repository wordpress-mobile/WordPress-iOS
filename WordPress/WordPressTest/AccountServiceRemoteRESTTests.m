#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "AccountServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "WPAccount.h"

@interface AccountServiceRemoteRESTTests : XCTestCase
@end

@implementation AccountServiceRemoteRESTTests

#pragma mark - Getting blogs

- (void)testThatGetBlogsWorks
{    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    AccountServiceRemoteREST *service = nil;
    
    NSString* url = @"v1.1/me/sites";
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[AccountServiceRemoteREST alloc] initWithApi:api]);
    
    [service getBlogsWithSuccess:^(NSArray *blogs) {}
                         failure:^(NSError *error) {}];
}

#pragma mark - Getting account details

- (void)testThatGetDetailsForAccountWorks
{
    WPAccount* account = OCMStrictClassMock([WPAccount class]);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    AccountServiceRemoteREST *service = nil;
    
    NSString* url = @"v1.1/me";
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[AccountServiceRemoteREST alloc] initWithApi:api]);
    
    [service getDetailsForAccount:account
                          success:^(RemoteUser *remoteUser) {}
                          failure:^(NSError *error) {}];
}

@end
