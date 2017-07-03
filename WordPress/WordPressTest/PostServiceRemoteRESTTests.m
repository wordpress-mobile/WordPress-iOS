#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "ContextManager.h"
#import "PostServiceRemoteREST.h"
#import "RemotePost.h"
#import "TestContextManager.h"

@interface PostServiceRemoteRESTTests : XCTestCase
@end

@implementation PostServiceRemoteRESTTests

#pragma mark - Common

/**
 *  @brief      Common method for instantiating and initializing the service object.
 *  @details    This is only useful for cases that don't need to mock the API object.
 *
 *  @returns    The newly created service object.
 */
- (PostServiceRemoteREST*)service
{
    WordPressComRestApi *api = [[WordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    NSNumber *siteID = @10;
    return [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:siteID];
}

#pragma mark - Getting posts by ID

- (void)testThatGetPostWithIDWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    PostServiceRemoteREST *service = nil;
    
    NSNumber *postID = @1;
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/posts/%@", dotComID, postID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNotNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);
    
    [service getPostWithID:postID
                   success:^(RemotePost *post) {}
                   failure:^(NSError *error) {}];
}

- (void)testThatGetPostWithIDThrowsExceptionWithoutPostID
{
    PostServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [self service]);
    XCTAssertThrows([service getPostWithID:nil
                                   success:^(RemotePost *post) {}
                                   failure:^(NSError *error) {}]);
}

#pragma mark - Getting posts by type

- (void)testThatGetPostsOfTypeWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    PostServiceRemoteREST *service = nil;
    
    NSString* postType = @"SomeType";
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/posts", dotComID];
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        
        return ([parameters isKindOfClass:[NSDictionary class]]
                && [[parameters objectForKey:@"type"] isEqualToString:postType]);
    };
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg checkWithBlock:parametersCheckBlock]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);

    [service getPostsOfType:postType
                    success:^(NSArray<RemotePost *> *remotePosts) {}
                    failure:^(NSError *error) {}];
}

- (void)testThatGetPostsOfTypeWithOptionsWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    PostServiceRemoteREST *service = nil;
    
    NSString* postType = @"SomeType";
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/posts", dotComID];
    
    NSString *testOptionKey = @"SomeKey";
    NSString *testOptionValue = @"SomeValue";
    NSDictionary *options = @{testOptionKey: testOptionValue};
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        
        return ([parameters isKindOfClass:[NSDictionary class]]
                && [[parameters objectForKey:@"type"] isEqualToString:postType]
                && [parameters objectForKey:testOptionKey] == testOptionValue);
    };
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg checkWithBlock:parametersCheckBlock]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);
    
    [service getPostsOfType:postType
                    options:options
                    success:^(NSArray<RemotePost *> *remotePosts) {}
                    failure:^(NSError *error) {}];
}

#pragma mark - Creating posts

- (void)testThatCreatePostWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    PostServiceRemoteREST *service = nil;
    
    RemotePost *post = OCMClassMock([RemotePost class]);
    OCMStub([post title]).andReturn(@"Title");
    OCMStub([post content]).andReturn(@"Content");
    OCMStub([post status]).andReturn(@"Status");
    OCMStub([post password]).andReturn(@"Password");
    OCMStub([post type]).andReturn(@"Type");
    OCMStub([post metadata]).andReturn(@[]);
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/posts/new?context=edit", dotComID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isKindOfClass:[NSDictionary class]]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);
    
    [service createPost:post
                success:^(RemotePost *posts) {}
                failure:^(NSError *error) {}];
}

- (void)testThatCreatePostThrowsExceptionWithoutPost
{
    PostServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [self service]);
    XCTAssertThrows([service createPost:nil
                                success:^(RemotePost *posts) {}
                                failure:^(NSError *error) {}]);
}

#pragma mark - Updating posts

- (void)testThatUpdatePostWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    PostServiceRemoteREST *service = nil;
    
    RemotePost *post = OCMClassMock([RemotePost class]);
    OCMStub([post postID]).andReturn(@1);
    OCMStub([post title]).andReturn(@"Title");
    OCMStub([post content]).andReturn(@"Content");
    OCMStub([post status]).andReturn(@"Status");
    OCMStub([post password]).andReturn(@"Password");
    OCMStub([post type]).andReturn(@"Type");
    OCMStub([post metadata]).andReturn(@[]);
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/posts/%@?context=edit", dotComID, post.postID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isKindOfClass:[NSDictionary class]]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);
    
    [service updatePost:post
                success:^(RemotePost *posts) {}
                failure:^(NSError *error) {}];
}

- (void)testThatUpdatePostThrowsExceptionWithoutPost
{
    PostServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [self service]);
    XCTAssertThrows([service updatePost:nil
                                success:^(RemotePost *posts) {}
                                failure:^(NSError *error) {}]);
}

#pragma mark - Deleting posts

- (void)testThatDeletePostWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    PostServiceRemoteREST *service = nil;
    
    RemotePost *post = OCMClassMock([RemotePost class]);
    OCMStub([post postID]).andReturn(@1);
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/posts/%@/delete", dotComID, post.postID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);
    
    [service deletePost:post
                success:^(RemotePost *posts) {}
                failure:^(NSError *error) {}];
}

- (void)testThatDeletePostThrowsExceptionWithoutPost
{
    PostServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [self service]);
    XCTAssertThrows([service deletePost:nil
                                success:^(RemotePost *posts) {}
                                failure:^(NSError *error) {}]);
}

#pragma mark - Trashing posts

- (void)testThatTrashPostWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    PostServiceRemoteREST *service = nil;
    
    RemotePost *post = OCMClassMock([RemotePost class]);
    OCMStub([post postID]).andReturn(@1);
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/posts/%@/delete", dotComID, post.postID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);
    
    [service trashPost:post
               success:^(RemotePost *posts) {}
               failure:^(NSError *error) {}];
}

- (void)testThatTashPostThrowsExceptionWithoutPost
{
    PostServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [self service]);
    XCTAssertThrows([service trashPost:nil
                               success:^(RemotePost *posts) {}
                               failure:^(NSError *error) {}]);
}

#pragma mark - Trashing posts

- (void)testThatRestorePostWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    PostServiceRemoteREST *service = nil;
    
    RemotePost *post = OCMClassMock([RemotePost class]);
    OCMStub([post postID]).andReturn(@1);
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/posts/%@/restore", dotComID, post.postID];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);
    
    [service restorePost:post
                 success:^(RemotePost *posts) {}
                 failure:^(NSError *error) {}];
}

- (void)testThatRestorePostThrowsExceptionWithoutPost
{
    PostServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [self service]);
    XCTAssertThrows([service restorePost:nil
                                 success:^(RemotePost *posts) {}
                                 failure:^(NSError *error) {}]);
}

@end
