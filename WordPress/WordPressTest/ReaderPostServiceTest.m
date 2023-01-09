#import "CoreDataStack.h"

#import <XCTest/XCTest.h>

#import "WPAccount.h"
#import "ReaderTopicService.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "WordPressTest-Swift.h"
@import WordPressKit;

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
    id<CoreDataStack> coreDataStack = [self coreDataStackForTesting];
    NSManagedObjectContext *context = [coreDataStack mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    RemoteReaderPost *remotePost = [self remoteReaderPostForTests];
    ReaderPost *post = [service createOrReplaceFromRemotePost:remotePost forTopic:nil];
    [coreDataStack saveContext:context];

    [service deletePostsWithNoTopic];
    XCTAssertTrue(post.isDeleted, @"The post should have been deleted.");


}

@end
