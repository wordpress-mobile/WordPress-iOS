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

@interface ReaderPostService()

- (ReaderPost *)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost forTopic:(ReaderAbstractTopic *)topic;
- (NSString *)removeInlineStyles:(NSString *)string;

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

- (void)testTitleIsPlainText {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    NSString *str = @"Sample text & sample text";
    RemoteReaderPost *remotePost = [self remoteReaderPostForTests];
    ReaderPost *post = [service createOrReplaceFromRemotePost:remotePost forTopic:nil];
    XCTAssertTrue([str isEqualToString:post.postTitle], @"The post title was not plain text.");
}

- (void)testSummaryIsPlainText {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    NSString *str = @"Sample text & sample text";
    RemoteReaderPost *remotePost = [self remoteReaderPostForTests];
    ReaderPost *post = [service createOrReplaceFromRemotePost:remotePost forTopic:nil];
    XCTAssertTrue([str isEqualToString:post.summary], @"The post summary was not plain text.");
}

- (void)testRemoveInlineStyleTags {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    NSString *str = @"<p >test</p><p >test</p>";
    NSString *styleStr = @"<p style=\"background-color:#fff;\">test</p><p style=\"background-color:#fff;\">test</p>";
    NSString *sanitizedStr = [service removeInlineStyles:styleStr];
    XCTAssertTrue([str isEqualToString:sanitizedStr], @"The inline styles were not removed.");

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

@end
