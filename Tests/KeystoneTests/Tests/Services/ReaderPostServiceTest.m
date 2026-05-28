
#import <XCTest/XCTest.h>

#import "ReaderTopicService.h"
#import "ReaderPostService.h"
#import "WordPressTest-Swift.h"
@import WordPressKit;

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
    remotePost.organizationID = @0;
    remotePost.sortRank = @1;

    return remotePost;
}

- (void)testDeletePostsWithoutATopic {
    id<CoreDataStack> coreDataStack = [self coreDataStackForTesting];

    ReaderPostService *service = [[ReaderPostService alloc] initWithCoreDataStack:coreDataStack];
    [coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        RemoteReaderPost *remotePost = [self remoteReaderPostForTests];
        [ReaderPost createOrUpdateWithRemotePost:remotePost topic:nil context:context];
    }];

    XCTAssertEqual([coreDataStack.mainContext countForFetchRequest:[ReaderPost fetchRequest] error:nil], 1);
    [service deletePostsWithNoTopic];
    XCTAssertEqual([coreDataStack.mainContext countForFetchRequest:[ReaderPost fetchRequest] error:nil], 0, @"The post should have been deleted.");
}

@end
