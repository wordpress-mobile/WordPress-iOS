#import "CoreDataTestHelper.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "ReaderTopic.h"
#import "ReaderTopicService.h"
#import "ReaderTopicServiceRemote.h"
#import "RemoteReaderTopic.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "ReaderPostServiceRemote.h"
#import "RemoteReaderPost.h"
#import <XCTest/XCTest.h>

@interface ReaderTopicTest : XCTestCase
@end

@implementation ReaderTopicTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
    [[CoreDataTestHelper sharedHelper] reset];
}


#pragma mark - Configuration

- (void)seedTopics
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderTopic *topic1 = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderTopic" inManagedObjectContext:context];
    topic1.path = @"topic1";
    topic1.title = @"topic1";
    topic1.type = ReaderTopicTypeList;

    ReaderTopic *topic2 = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderTopic" inManagedObjectContext:context];
    topic2.path = @"topic2";
    topic2.title = @"topic2";
    topic2.type = ReaderTopicTypeTag;

    ReaderTopic *topic3 = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderTopic" inManagedObjectContext:context];
    topic3.path = @"topic3";
    topic3.title = @"topic3";
    topic3.title = ReaderTopicTypeTag;
    NSError *error;
    [context save:&error];
}

- (NSUInteger)countTopics
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ReaderTopic"];
    NSError *error;
    return [context countForFetchRequest:request error:&error];
}

- (void)seedPostsForTopic:(ReaderTopic *)topic {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPost *post1 = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost" inManagedObjectContext:context];
    post1.postID = @1;
    post1.postTitle = @"post1";
    post1.content = @"post1";
    post1.topic = topic;

    ReaderPost *post2 = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost" inManagedObjectContext:context];
    post2.postID = @2;
    post2.postTitle = @"post2";
    post2.content = @"post2";
    post2.topic = topic;

    ReaderPost *post3 = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost" inManagedObjectContext:context];
    post3.postID = @3;
    post3.postTitle = @"post3";
    post3.content = @"post3";
    post3.topic = topic;

    NSError *error;
    [context save:&error];
    XCTAssertNil(error, @"Error saving posts.");

}

#pragma mark - ReaderTopic tests

- (void)testDeleteAllTopics
{

    [self seedTopics];
    XCTAssertFalse([self countTopics] == 0, @"Number of ReaderTopics should be not be zero after seedeing.");
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:context];

    [service deleteAllTopics];

    XCTAssertTrue([self countTopics] == 0, @"Number of ReaderTopics should be zero.");

}


- (void)testPostsDeletedWhenTopicDeleted
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderTopic *topic1 = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderTopic" inManagedObjectContext:context];
    topic1.path = @"topic1";
    topic1.title = @"topic1";
    topic1.type = ReaderTopicTypeList;

    [self seedPostsForTopic:topic1];
    XCTAssertTrue([topic1.posts count] > 0, @"Topic should have posts relationship with three posts.");

    [context deleteObject:topic1];
    NSError *error;
    [context save:&error];
    XCTAssertNil(error, @"There was an error saving the context after deleting a topic.");

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
    XCTAssertTrue(count == 0, @"Topic was not deleted successfully");

    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ReaderPost"];
    count = [context countForFetchRequest:fetchRequest error:&error];
    XCTAssertTrue(count == 0, @"Topic posts were not successfully deleted.");
}


@end
