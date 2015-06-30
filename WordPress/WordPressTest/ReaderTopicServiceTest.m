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
#import "TestContextManager.h"


@interface ReaderTopicServiceRemote()
- (RemoteReaderTopic *)normalizeTopicDictionary:(NSDictionary *)topicDict subscribed:(BOOL)subscribed recommended:(BOOL)recommended;
@end

@interface ReaderTopicService()
- (void)mergeMenuTopics:(NSArray *)topics forAccount:(WPAccount *)account;
- (NSString *)formatTitle:(NSString *)str;
@end


@interface ReaderTopicServiceTest : XCTestCase

@property (nonatomic, strong) TestContextManager *testContextManager;

@end

@implementation ReaderTopicServiceTest

- (void)setUp
{
    [super setUp];
    
    self.testContextManager = [[TestContextManager alloc] init];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    
    self.testContextManager = nil;
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

#pragma mark - ReaderTopicServiceRemote tests

/**
 Ensure dictionaries via a reset response are correctly formatted and saved to a RemoteReaderTopic object
 */
- (void)testNormalizingTopicDictionary {
    NSDictionary *topicDictionaryWithID = @{
                                            @"ID": @"16166",
                                            @"title": @"Coffee",
                                            @"URL": @"https://public-api.wordpress.com/rest/v1/read/tags/coffee/posts"
                                            };
    NSDictionary *topicDictionaryWithoutID = @{
                                               @"title": @"Coffee",
                                               @"URL": @"https://public-api.wordpress.com/rest/v1/read/tags/coffee/posts"
                                               };

    ReaderTopicServiceRemote *remoteService = [[ReaderTopicServiceRemote alloc] initWithRemoteApi:nil];
    RemoteReaderTopic *remoteTopic = [remoteService normalizeTopicDictionary:topicDictionaryWithID subscribed:YES recommended:YES];
    XCTAssertTrue(remoteTopic.isRecommended, @"Remote topic should be recommended but wasn't.");
    XCTAssertTrue(remoteTopic.isSubscribed, @"Remote topic should be subscribed but wasn't.");
    XCTAssertEqual(remoteTopic.path, topicDictionaryWithID[@"URL"], @"Remote topic path did not match.");
    XCTAssertEqual(remoteTopic.title, topicDictionaryWithID[@"title"], @"Remote topic title did not match.");
    XCTAssertEqual([remoteTopic.topicID integerValue], [topicDictionaryWithID[@"ID"] integerValue], @"Remote topic ID did not match.");

    remoteTopic = [remoteService normalizeTopicDictionary:topicDictionaryWithoutID subscribed:NO recommended:NO];
    XCTAssertFalse(remoteTopic.isRecommended, @"Remote topic should not be recommended but was.");
    XCTAssertFalse(remoteTopic.isSubscribed, @"Remote topic should not be subscribed but was.");
    XCTAssertEqual(remoteTopic.path, topicDictionaryWithID[@"URL"], @"Remote topic path did not match.");
    XCTAssertEqual(remoteTopic.title, topicDictionaryWithID[@"title"], @"Remote topic title did not match.");
    XCTAssertEqual(remoteTopic.topicID, @0, @"Remote topic ID was not 0.");
}


#pragma mark - ReaderTopicService tests

/**
 @return an array of RemoteReaderTopic objects for use in tests.
 */
- (NSArray *)remoteTopicsForTests {
    RemoteReaderTopic *foo = [[RemoteReaderTopic alloc] init];
    foo.topicID = @1;
    foo.title = @"foo";
    foo.path = @"http://foo.com";
    foo.isSubscribed = YES;
    foo.isMenuItem = YES;
    foo.type = ReaderTopicTypeList;

    RemoteReaderTopic *bar = [[RemoteReaderTopic alloc] init];
    bar.title = @"bar";
    bar.path = @"http://bar.com";
    bar.isMenuItem = YES;
    bar.type = ReaderTopicTypeList;

    RemoteReaderTopic *baz = [[RemoteReaderTopic alloc] init];
    baz.title = @"baz";
    baz.path = @"http://baz.com";
    baz.isMenuItem = YES;
    baz.type = ReaderTopicTypeList;

    return @[foo, bar, baz];
}

/**
 Ensure that topics a user unsubscribes from are removed from core data when merging
 results from the REST API.
 */
- (void)testUnsubscribedTopicIsRemovedDuringSync {
    NSArray *remoteTopics = [self remoteTopicsForTests];

    // Setup
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
    [service mergeMenuTopics:remoteTopics forAccount:nil];

    // Topics exist in the context
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    NSError *error;
    NSUInteger count = [context countForFetchRequest:request error:&error];
    XCTAssertEqual(count, [remoteTopics count], @"Number of topics in context did not match expected.");

    // Merg new set of topics.
    RemoteReaderTopic *foo = remoteTopics.firstObject;
    [service mergeMenuTopics:@[foo] forAccount:nil];

    // Make sure the missing topics were removed when merged
    count = [context countForFetchRequest:request error:&error];
    XCTAssertEqual(count, 1, @"The number of topics in the context did not match what was expected.");

    NSArray *results = [context executeFetchRequest:request error:&error];
    ReaderTopic *topic = (ReaderTopic *)[results firstObject];
    XCTAssertEqual(topic.topicID, foo.topicID, @"The ReaderTopic returned was not the one expected.");
}

/**
 Ensure that topics a user subscribes to are added to core data when merging
 results from the REST API.
 */
- (void)testNewlySubscribedTopicIsAddedDuringSync {
    NSArray *remoteTopics = [self remoteTopicsForTests];

    RemoteReaderTopic *foo = remoteTopics[0];
    NSArray *startingTopics = @[remoteTopics[1], remoteTopics[2]];

    // Setup
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
    [service mergeMenuTopics:startingTopics forAccount:nil];

    // Topics exist in the context
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    request.sortDescriptors = @[sortDescriptor];
    NSError *error;
    NSUInteger count = [context countForFetchRequest:request error:&error];
    XCTAssertEqual(count, [startingTopics count], @"Number of topics in context did not match expected.");

    // Merg new set of topics.
    [service mergeMenuTopics:remoteTopics forAccount:nil];

    // Make sure the missing topics were added when merged
    count = [context countForFetchRequest:request error:&error];
    XCTAssertEqual(count, [remoteTopics count], @"The number of topics in the context did not match what was expected.");

    NSArray *results = [context executeFetchRequest:request error:&error];
    ReaderTopic *topic = (ReaderTopic *)[results lastObject];
    XCTAssertEqual(topic.topicID, foo.topicID, @"The ReaderTopic returned was not the one expected.");

}

/**
 Ensure that a default topic can be set and retrieved.
 */
- (void)testGettingSettingCurrentTopic {
    NSArray *remoteTopics = [self remoteTopicsForTests];

    // Setup
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
    service.currentTopic = nil;

    // Current topic is not nil after a sync
    [service mergeMenuTopics:remoteTopics forAccount:nil];
    XCTAssertNotNil(service.currentTopic, @"The current topic was nil.");

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    request.sortDescriptors = @[sortDescriptor];
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];

    ReaderTopic *topic = [results lastObject];
    XCTAssertNotEqual(service.currentTopic.path, topic.path, @"The current topic mached the topic fetched.");

    service.currentTopic = topic;
    XCTAssertEqual(service.currentTopic.path, topic.path, @"The current topic did not match the topic we assiged to it.");
}

/**
 Ensure all topics are deleted when an account is changed.
 */
- (void)testDeleteAllTopics
{

    [self seedTopics];
    XCTAssertFalse([self countTopics] == 0, @"Number of ReaderTopics should be not be zero after seedeing.");
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:context];

    [service deleteAllTopics];

    XCTAssertTrue([self countTopics] == 0, @"Number of ReaderTopics should be zero.");

}

/**
 Ensure all the posts belonging to a topic are deleted when the topic is deleted.
 */
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

- (void)testTopicTitleFormatting
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
    NSString *unformatted;
    NSString *formatted;

    // Capitalized first char assumes the string has correct case
    unformatted = @"WordPress";
    formatted = [service formatTitle:unformatted];
    XCTAssertTrue([formatted isEqualToString:unformatted], @"WordPress should have maintained its case.");

    // Lowercase should be capitalized
    unformatted = @"art & entertainment";
    formatted = [service formatTitle:unformatted];
    XCTAssertTrue([formatted isEqualToString:@"Art & Entertainment"], @"Lower cased words should be capitalized");

    // Special consideration for the casing of "techy" words like iPhone and ePaper.
    unformatted = @"iPhone";
    formatted = [service formatTitle:unformatted];
    XCTAssertTrue([formatted isEqualToString:unformatted], @"iPhone should have maintained its case.");

    unformatted = @"ePaper";
    formatted = [service formatTitle:unformatted];
    XCTAssertTrue([formatted isEqualToString:unformatted], @"ePaper should have maintained its case.");

    // All caps stays all caps.
    unformatted = @"VINE";
    formatted = [service formatTitle:unformatted];
    XCTAssertTrue([formatted isEqualToString:unformatted], @"VINE should have remained all caps.");
}

@end
