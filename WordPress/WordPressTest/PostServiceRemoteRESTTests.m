#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "ContextManager.h"
#import "PostServiceRemoteREST.h"
#import "TestContextManager.h"
#import "WordPressComApi.h"

@interface PostServiceRemoteRESTTests : XCTestCase
@end

@implementation PostServiceRemoteRESTTests

/*
 - (void)getPostWithID:(NSNumber *)postID
 forBlog:(Blog *)blog
 success:(void (^)(RemotePost *post))success
 failure:(void (^)(NSError *))failure;
 
 - (void)getPostsOfType:(NSString *)postType
 forBlog:(Blog *)blog
 success:(void (^)(NSArray *posts))success
 failure:(void (^)(NSError *error))failure;
 
 - (void)getPostsOfType:(NSString *)postType
 forBlog:(Blog *)blog
 options:(NSDictionary *)options
 success:(void (^)(NSArray *posts))success
 failure:(void (^)(NSError *error))failure;
 
 - (void)createPost:(RemotePost *)post
 forBlog:(Blog *)blog
 success:(void (^)(RemotePost *post))success
 failure:(void (^)(NSError *error))failure;
 
 - (void)updatePost:(RemotePost *)post
 forBlog:(Blog *)blog
 success:(void (^)(RemotePost *post))success
 failure:(void (^)(NSError *error))failure;
 
 - (void)deletePost:(RemotePost *)post
 forBlog:(Blog *)blog
 success:(void (^)())success
 failure:(void (^)(NSError *error))failure;
 
 - (void)trashPost:(RemotePost *)post
 forBlog:(Blog *)blog
 success:(void (^)(RemotePost *))success
 failure:(void (^)(NSError *))failure;
 
 - (void)restorePost:(RemotePost *)post
 forBlog:(Blog *)blog
 success:(void (^)(RemotePost *))success
 failure:(void (^)(NSError *error))failure;

 */

#pragma mark - Common

/**
 *  @brief      Common method for instantiating and initializing the service object.
 *
 *  @returns    The newly created service object.
 */
- (PostServiceRemoteREST*)service
{
    WordPressComApi *api = [[WordPressComApi alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    return [[PostServiceRemoteREST alloc] initWithApi:api];
}

#pragma mark - Getting posts

- (void)testGetPostWithID
{
    NSManagedObjectContext *tempContext = [[TestContextManager sharedInstance] mainContext];// [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                                                                                            //tempContext.parentContext = [[TestContextManager sharedInstance] mainContext];

    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Blog class])
                                              inManagedObjectContext:tempContext];
    Blog *blog = [[Blog alloc] initWithEntity:entity
               insertIntoManagedObjectContext:tempContext];
    
    PostServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [self service]);
    [service getPostWithID:@1
                   forBlog:blog
                   success:^(RemotePost *post) {
                   }
                   failure:^(NSError *error) {
                   }];
    
    [tempContext rollback];
}

- (void)testGetPostWithNilPostIDThrowsException
{
    PostServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [self service]);
    XCTAssertThrows([service getPostWithID:nil
                                   forBlog:nil
                                   success:nil
                                   failure:nil]);
}

- (void)testGetPostWithNilBlogThrowsException
{
    PostServiceRemoteREST *service = nil;
    
    XCTAssertNoThrow(service = [self service]);
    XCTAssertThrows([service getPostWithID:@2
                                   forBlog:nil
                                   success:nil
                                   failure:nil]);
}

@end
