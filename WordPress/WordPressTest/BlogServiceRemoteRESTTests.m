#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "BlogServiceRemoteREST.h"
#import "WordPressComApi.h"

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
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@", blog.dotComID];
    
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
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/post-formats", blog.dotComID];
    
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

@end
