#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "BlogServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Publicizer.h"

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
    
    NSString* url = [NSString stringWithFormat:@"sites/%@/users", blog.dotComID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isKindOfClass:[NSDictionary class]]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service checkMultiAuthorForBlog:blog
                             success:^(BOOL isMultiAuthor) {}
                             failure:^(NSError *error) {}];
}


- (void)testThatCheckMultiAuthorForBlogThrowsExceptionWithoutBlog
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service checkMultiAuthorForBlog:nil
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
    
    NSString* url = [NSString stringWithFormat:@"sites/%@", blog.dotComID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service syncOptionsForBlog:blog
                        success:^(NSDictionary *options) {}
                        failure:^(NSError *error) {}];
}

- (void)testThatSyncOptionForBlogThrowsExceptionWithoutBlog
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service syncOptionsForBlog:nil
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
    
    NSString* url = [NSString stringWithFormat:@"sites/%@/post-formats", blog.dotComID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service syncPostFormatsForBlog:blog
                            success:^(NSDictionary *options) {}
                            failure:^(NSError *error) {}];
}

- (void)testThatSyncPostFormatsForBlogThrowsExceptionWithoutBlog
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service syncPostFormatsForBlog:nil
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
    
    NSString* url = [NSString stringWithFormat:@"sites/%@/connections", blog.dotComID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service syncConnectionsForBlog:blog
                            success:^(NSArray *connections) {}
                            failure:^(NSError *error) {}];
}

- (void)testThatSyncConnectionsForBlogThrowsExceptionWithoutBlog
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service syncConnectionsForBlog:nil
                                            success:^(NSArray *connections) {}
                                            failure:^(NSError *error) {}]);
}

#pragma mark - Publicizer management for a blog

- (void)testThatCheckAuthorizationForPublicizerWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    Publicizer *publicizer = OCMStrictClassMock([Publicizer class]);
    OCMStub([publicizer blog]).andReturn(blog);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString *url = @"me/keyring-connections";
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service checkAuthorizationForPublicizer:publicizer
                                     success:^(NSDictionary *authorization) {}
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
                                                     success:^(NSDictionary *authorization) {}
                                                     failure:^(NSError *error) {}]);
    XCTAssertThrows([service checkAuthorizationForPublicizer:publicizer
                                                     success:^(NSDictionary *authorization) {}
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
    
    NSString *url = [NSString stringWithFormat:@"sites/%@/publicize-connections/new", blog.dotComID];

    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNotNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service connectPublicizer:publicizer
             withAuthorization:@{@"ID":@"keyring"}
                       success:^(NSArray *connections) {}
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
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    XCTAssertThrows([service connectPublicizer:nil
                             withAuthorization:@{@"ID":@"keyring"}
                                       success:^(NSArray *connections) {}
                                       failure:^(NSError *error) {}]);
    XCTAssertThrows([service connectPublicizer:publicizer
                             withAuthorization:@{}
                                       success:^(NSArray *connections) {}
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
    
    NSString *url = [NSString stringWithFormat:@"sites/%@/connections/%d/delete", blog.dotComID, (int)publicizer.connectionID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithApi:api]);
    
    [service disconnectPublicizer:publicizer
                          success:^(NSArray *connections) {}
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
                                          success:^(NSArray *connections) {}
                                          failure:^(NSError *error) {}]);
    XCTAssertThrows([service disconnectPublicizer:publicizer
                                          success:^(NSArray *connections) {}
                                          failure:^(NSError *error) {}]);
}

@end
