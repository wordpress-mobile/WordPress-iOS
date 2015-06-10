#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "AccountServiceRemoteREST.h"
#import "WordPressComApi.h"

@interface AccountServiceRemoteRESTTests : XCTestCase
@end

@implementation AccountServiceRemoteRESTTests

#pragma mark - Getting blogs

- (void)testThatGetBlogsWorks
{    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    AccountServiceRemoteREST *service = nil;
    
    NSString* url = @"me/sites";
    
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
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    AccountServiceRemoteREST *service = nil;
    
    NSString* url = @"me";
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[AccountServiceRemoteREST alloc] initWithApi:api]);
    
    [service getDetailsForAccount:nil
                          success:^(RemoteUser *remoteUser) {}
                          failure:^(NSError *error) {}];
}

@end
