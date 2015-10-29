#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "BlogServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Publicizer.h"
#import "PublicizerServiceRemote.h"

@implementation Publicizer(UnitTesting)
- (Blog *)blog { return nil; }
@end

@interface BlogServiceRemoteRESTTests : XCTestCase
@end

@implementation BlogServiceRemoteRESTTests

#pragma mark - Checking multi author for a blog

- (void)testThatCheckMultiAuthorForBlogWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/users", blog.dotComID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isKindOfClass:[NSDictionary class]]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service checkMultiAuthorForBlogID:[blog dotComID]
                             success:^(BOOL isMultiAuthor) {}
                             failure:^(NSError *error) {}];
}


- (void)testThatCheckMultiAuthorForBlogThrowsExceptionWithoutBlog
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service checkMultiAuthorForBlogID:nil
                                             success:^(BOOL isMultiAuthor) {}
                                             failure:^(NSError *error) {}]);
}

#pragma mark - Synchronizing options for a blog

- (void)testThatSyncOptionForBlogWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@", blog.dotComID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service syncOptionsForBlogID:[blog dotComID]
                          success:^(NSDictionary *options) {}
                          failure:^(NSError *error) {}];
}

- (void)testThatSyncOptionForBlogThrowsExceptionWithoutBlog
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service syncOptionsForBlogID:nil
                                        success:^(NSDictionary *options) {}
                                        failure:^(NSError *error) {}]);
}

#pragma mark - Synchronizing post formats for a blog

- (void)testThatSyncPostFormatsForBlogWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/post-formats", blog.dotComID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service syncPostFormatsForBlogID:[blog dotComID]
                              success:^(NSDictionary *options) {}
                              failure:^(NSError *error) {}];
}

- (void)testThatSyncPostFormatsForBlogThrowsExceptionWithoutBlog
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service syncPostFormatsForBlogID:nil
                                            success:^(NSDictionary *options) {}
                                            failure:^(NSError *error) {}]);
}

#pragma mark - Synchronizing connections for a blog

- (void)testThatSyncConnectionsForBlogWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/connections", blog.dotComID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service syncConnectionsForBlogID:blog.dotComID
                            success:^(NSArray *connections) {}
                            failure:^(NSError *error) {}];
}

- (void)testThatSyncConnectionsForBlogThrowsExceptionWithoutBlog
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service syncConnectionsForBlogID:nil
                                            success:^(NSArray *connections) {}
                                            failure:^(NSError *error) {}]);
}

#pragma mark - Publicizer management for a blog

- (void)testThatGetPublicizersWorks
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    PublicizerServiceRemote *service = nil;
    
    NSString *url = @"v1.1/meta/publicize/";
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[PublicizerServiceRemote alloc] initWithApi:api]);
  
    [service getPublicizersWithSuccess:^(NSArray *publicizers){}
                               failure:^(NSError *error) {}];
}

- (void)testThatCheckAuthorizationForPublicizerWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    Publicizer *publicizer = OCMStrictClassMock([Publicizer class]);
    OCMStub([publicizer blog]).andReturn(blog);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString *url = @"v1.1/me/keyring-connections";
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service checkAuthorizationForPublicizer:publicizer
                                     success:^(NSArray *accounts) {}
                                     failure:^(NSError *error) {}];
}

- (void)testThatCheckAuthorizationForPublicizerThrowsExceptionWithoutBlog
{
    Publicizer *publicizer = OCMStrictClassMock([Publicizer class]);
    OCMStub([publicizer blog]).andReturn(nil);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service checkAuthorizationForPublicizer:nil
                                                     success:^(NSArray *accounts) {}
                                                     failure:^(NSError *error) {}]);
    XCTAssertThrows([service checkAuthorizationForPublicizer:publicizer
                                                     success:^(NSArray *accounts) {}
                                                     failure:^(NSError *error) {}]);
}

- (void)testThatConnectPublicizerWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    Publicizer *publicizer = OCMStrictClassMock([Publicizer class]);
    OCMStub([publicizer blog]).andReturn(blog);

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/publicize-connections/new", blog.dotComID];

    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNotNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service connectPublicizer:publicizer
             withAuthorization:@(1001)
                    andAccount:nil
                       success:^{}
                       failure:^(NSError *error) {}];
}

- (void)testThatConnectPublicizerThrowsExceptionWithoutAuthorization
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    Publicizer *publicizer = OCMStrictClassMock([Publicizer class]);
    OCMStub([publicizer blog]).andReturn(blog);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/publicize-connections/new", blog.dotComID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNotNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    XCTAssertThrows([service connectPublicizer:nil
                             withAuthorization:@(1002)
                                    andAccount:nil
                                       success:^{}
                                       failure:^(NSError *error) {}]);
    XCTAssertThrows([service connectPublicizer:publicizer
                             withAuthorization:nil
                                    andAccount:nil
                                       success:^{}
                                       failure:^(NSError *error) {}]);
}

- (void)testThatDisconnectPublicizerWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    Publicizer *publicizer = OCMStrictClassMock([Publicizer class]);
    OCMStub([publicizer blog]).andReturn(blog);
    OCMStub([publicizer connectionID]).andReturn(10);

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/connections/%d/delete", blog.dotComID, (int)publicizer.connectionID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service disconnectPublicizer:publicizer
                          success:^{}
                          failure:^(NSError *error) {}];
}

- (void)testThatDisconnectPublicizerThrowsExceptionWithoutBlog
{
    Publicizer *publicizer = OCMStrictClassMock([Publicizer class]);
    OCMStub([publicizer blog]).andReturn(nil);

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service disconnectPublicizer:nil
                                          success:^{}
                                          failure:^(NSError *error) {}]);
    XCTAssertThrows([service disconnectPublicizer:publicizer
                                          success:^{}
                                          failure:^(NSError *error) {}]);
}

@end
