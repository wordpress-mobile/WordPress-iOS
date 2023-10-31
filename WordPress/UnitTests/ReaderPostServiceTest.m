#import "CoreDataStack.h"

#import <XCTest/XCTest.h>

#import "WPAccount.h"
#import "ReaderTopicService.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "UnitTests-Swift.h"
@import WordPressKit;

@interface ReaderPostService()

- (ReaderPost *)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost forTopic:(ReaderAbstractTopic *)topic inContext:(NSManagedObjectContext *)context;

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
    remotePost.organizationID = @0;
    remotePost.sortRank = @1;

    return remotePost;
}

- (void)testDeletePostsWithoutATopic {
    id<CoreDataStack> coreDataStack = [self coreDataStackForTesting];

    ReaderPostService *service = [[ReaderPostService alloc] initWithCoreDataStack:coreDataStack];
    [coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        RemoteReaderPost *remotePost = [self remoteReaderPostForTests];
        [service createOrReplaceFromRemotePost:remotePost forTopic:nil inContext:context];
    }];

    XCTAssertEqual([coreDataStack.mainContext countForFetchRequest:[ReaderPost fetchRequest] error:nil], 1);
    [service deletePostsWithNoTopic];
    XCTAssertEqual([coreDataStack.mainContext countForFetchRequest:[ReaderPost fetchRequest] error:nil], 0, @"The post should have been deleted.");
}

@end
