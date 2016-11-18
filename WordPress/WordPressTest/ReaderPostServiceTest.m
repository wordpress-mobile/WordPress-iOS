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
#import "WordPress-Swift.h"

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
    remotePost.sortRank = @0;
    return remotePost;
}

- (void)testDeletePostsWithoutATopic {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    RemoteReaderPost *remotePost = [self remoteReaderPostForTests];
    ReaderPost *post = [service createOrReplaceFromRemotePost:remotePost forTopic:nil];
    [[ContextManager sharedInstance] saveContextAndWait:context];

    [service deletePostsWithNoTopic];
    XCTAssertTrue(post.isDeleted, @"The post should have been deleted.");
}

- (void)testDoesntDeleteSavedPosts {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];
    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:context];

    ReaderAbstractTopic *savedTopic = [topicService savedPostsTopic];
    RemoteReaderPost *remotePost = [self remoteReaderPostForTests];
    ReaderPost *post = [service createOrReplaceFromRemotePost:remotePost forTopic:savedTopic];

    [service deletePostsWithNoTopic];

    [[ContextManager sharedInstance] saveContextAndWait:context];

    XCTAssertTrue(!post.isDeleted, @"The post should not have been deleted.");
}

@end
