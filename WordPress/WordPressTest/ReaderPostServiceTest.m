#import "ContextManager.h"

#import <XCTest/XCTest.h>

#import "WPAccount.h"
#import "ReaderTopicService.h"
#import "ReaderTopicServiceRemote.h"
#import "RemoteReaderTopic.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "RemoteReaderPost.h"
#import "TestContextManager.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface ReaderPostService()

- (ReaderPost *)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost forTopic:(ReaderAbstractTopic *)topic;

@end

@interface ReaderPostServiceTest : XCTestCase
@end

@implementation ReaderPostServiceTest


#pragma mark - ReaderPostService tests

- (RemoteReaderPost *)remoteReaderPostForTests {
    NSString *str = @"<h1>Sample <b>text</b> &amp; sample text</h1>";
    RemoteReaderPost *remotePost = [[RemoteReaderPost alloc] init];
    remotePost.content = @"";
    remotePost.postTitle = str;
    remotePost.summary = str;

    return remotePost;
}

- (void)testDeletePostsWithoutATopic {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    RemoteReaderPost *remotePost = [self remoteReaderPostForTests];
    ReaderPost *post = [service createOrReplaceFromRemotePost:remotePost forTopic:nil];
    [[ContextManager sharedInstance] saveContext:context];

    [service deletePostsWithNoTopic];
    XCTAssertTrue(post.isDeleted, @"The post should have been deleted.");
}

- (void)testGetPostFromCacheWhenNoInternetConnection {

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.path containsString:@"read/sites/2000/posts/1000"];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSError *error = [NSError errorWithDomain:@"" code:NSURLErrorNotConnectedToInternet userInfo:nil];
        return [OHHTTPStubsResponse responseWithError:error];
    }];

    NSUInteger postID = 1000;
    NSUInteger siteID = 2000;

    XCTestExpectation * exp = [self expectationWithDescription:@"Cached Post"];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    [self insertPostWithID:postID siteID:siteID inContext:context];

    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPost:postID forSite:siteID success:^(ReaderPost *post, BOOL cached) {

        XCTAssertTrue(cached);
        XCTAssertEqual(post.postID.unsignedIntegerValue, postID);
        XCTAssertEqual(post.siteID.unsignedIntegerValue, siteID);
        [exp fulfill];

    } failure:nil];

    [self waitForExpectationsWithTimeout:0.3 handler:^(NSError * _Nullable error) {
        if (error){
            XCTFail("ReaderPostService fetch post timeout");
        }
    }];
}

- (void)testFailToFetchPostOnOtherError {

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.path containsString:@"read/sites/2000/posts/1000"];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSError *error = [NSError errorWithDomain:@"" code:NSURLErrorBadURL userInfo:nil];
        return [OHHTTPStubsResponse responseWithError:error];
    }];

    NSUInteger postID = 1000;
    NSUInteger siteID = 2000;

    XCTestExpectation * exp = [self expectationWithDescription:@"Not internet error"];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    [self insertPostWithID:postID siteID:siteID inContext:context];

    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPost:postID forSite:siteID success:nil failure:^(NSError *error) {
        XCTAssertNotNil(error);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.3 handler:^(NSError * _Nullable error) {
        if (error){
            XCTFail("ReaderPostService fetch post timeout");
        }
    }];
}

- (void)testFailIfNotCachedPostAndNoInternetConnection {

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.path containsString:@"read/sites/2001/posts/1001"];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSError *error = [NSError errorWithDomain:@"" code:NSURLErrorNotConnectedToInternet userInfo:nil];
        return [OHHTTPStubsResponse responseWithError:error];
    }];

    NSUInteger postID = 1001;
    NSUInteger siteID = 2001;

    XCTestExpectation * exp = [self expectationWithDescription:@"Not cached Post"];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    [service fetchPost:postID forSite:siteID success:nil failure:^(NSError *error) {
        XCTAssertNotNil(error);
        [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.3 handler:^(NSError * _Nullable error) {
        if (error){
            XCTFail("ReaderPostService fetch post timeout");
        }
    }];
}

- (void)insertPostWithID:(NSUInteger)postID
                  siteID:(NSUInteger)siteID
               inContext:(NSManagedObjectContext *)context {

    ReaderPost *post = (ReaderPost *)[NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost"
                                                                   inManagedObjectContext:context];
    post.postID = @(postID);
    post.siteID = @(siteID);
    [[ContextManager sharedInstance] saveContext:context];
}

-(void)tearDown {
    [super tearDown];
    [OHHTTPStubs removeAllStubs];
}

@end
