#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "PostServiceRemoteREST.h"
#import "RemotePost.h"
#import <WordPressKit/WordPressKit-Swift.h>

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

    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);

    NSNumber *postID = @1;
    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/posts/%@", dotComID, postID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNotNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);

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

    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);

    NSString* postType = @"SomeType";

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/posts", dotComID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        
        return ([parameters isKindOfClass:[NSDictionary class]]
                && [[parameters objectForKey:@"type"] isEqualToString:postType]);
    };
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg checkWithBlock:parametersCheckBlock]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    

    [service getPostsOfType:postType
                    success:^(NSArray<RemotePost *> *remotePosts) {}
                    failure:^(NSError *error) {}];
}

- (void)testThatGetPostsOfTypeWithOptionsWorks
{
    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    PostServiceRemoteREST *service = nil;

    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);

    NSString* postType = @"SomeType";

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/posts", dotComID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

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

    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/posts/new?context=edit", dotComID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isKindOfClass:[NSDictionary class]]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

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
    
    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/posts/%@?context=edit", dotComID, post.postID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isKindOfClass:[NSDictionary class]]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

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

    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/posts/%@/delete", dotComID, post.postID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

    [service deletePost:post
                success:^() {}
                failure:^(NSError *error) {}];
}

- (void)testThatDeletePostThrowsExceptionWithoutPost
{
    PostServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [self service]);
    XCTAssertThrows([service deletePost:nil
                                success:^() {}
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

    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/posts/%@/delete", dotComID, post.postID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

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

    XCTAssertNoThrow(service = [[PostServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/posts/%@/restore", dotComID, post.postID];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);

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
