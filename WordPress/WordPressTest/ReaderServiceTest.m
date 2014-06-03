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

@interface ReaderServiceTest : XCTestCase
@end

@interface ReaderTopicServiceRemote()

- (RemoteReaderTopic *)normalizeTopicDictionary:(NSDictionary *)topicDict subscribed:(BOOL)subscribed recommended:(BOOL)recommended;

@end

@interface ReaderTopicService()

- (void)mergeTopics:(NSArray *)topics forAccount:(WPAccount *)account;

@end

@interface ReaderPostServiceRemote ()

- (RemoteReaderPost *)formatPostDictionary:(NSDictionary *)dict;
- (BOOL)siteIsPrivateFromPostDictionary:(NSDictionary *)dict;
- (NSString *)siteURLFromPostDictionary:(NSDictionary *)dict;
- (NSString *)siteNameFromPostDictionary:(NSDictionary *)dict;
- (NSString *)featuredImageFromPostDictionary:(NSDictionary *)dict;
- (NSString *)sortDateFromPostDictionary:(NSDictionary *)dict;
- (BOOL)isWPComFromPostDictionary:(NSDictionary *)dict;
- (NSString *)authorEmailFromAuthorDictionary:(NSDictionary *)dict;
- (NSString *)sanitizeFeaturedImageString:(NSString *)img;

@end

@interface ReaderPostService()

- (ReaderPost *)createOrReplaceFromRemotePost:(RemoteReaderPost *)remotePost forTopic:(ReaderTopic *)topic;
- (NSString *)removeInlineStyles:(NSString *)string;

@end


@implementation ReaderServiceTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
    [[CoreDataTestHelper sharedHelper] reset];
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

    RemoteReaderTopic *bar = [[RemoteReaderTopic alloc] init];
    bar.title = @"bar";
    bar.path = @"http://bar.com";

    RemoteReaderTopic *baz = [[RemoteReaderTopic alloc] init];
    baz.title = @"baz";
    baz.path = @"http://baz.com";

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
    [service mergeTopics:remoteTopics forAccount:nil];

    // Topics exist in the context
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    NSError *error;
    NSUInteger count = [context countForFetchRequest:request error:&error];
    XCTAssertEqual(count, [remoteTopics count], @"Number of topics in context did not match expected.");

    // Merg new set of topics.
    RemoteReaderTopic *foo = remoteTopics.firstObject;
    [service mergeTopics:@[foo] forAccount:nil];

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
    [service mergeTopics:startingTopics forAccount:nil];

    // Topics exist in the context
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderTopic"];
    request.sortDescriptors = @[sortDescriptor];
    NSError *error;
    NSUInteger count = [context countForFetchRequest:request error:&error];
    XCTAssertEqual(count, [startingTopics count], @"Number of topics in context did not match expected.");

    // Merg new set of topics.
    [service mergeTopics:remoteTopics forAccount:nil];

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
    [service mergeTopics:remoteTopics forAccount:nil];
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


#pragma mark - ReaderPostServiceRemote tests

- (NSDictionary *)metaDictionaryWithKey:(NSString *)key value:(id)value {
    NSDictionary *site = [NSDictionary dictionaryWithObject:value forKey:key];
    return @{
             @"meta": @{@"data": @{
                                @"site": site
                                }
                        }
             };
}

- (NSDictionary *)editorialDictionaryWithKey:(NSString *)key value:(id)value {
    NSDictionary *editorial = [NSDictionary dictionaryWithObject:value forKey:key];
    return @{@"editorial":editorial};
}

- (void)testNormalizingPostDictionary {

}

- (void)testSiteIsPrivate {
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:nil];


    NSDictionary *dict = @{@"site_is_private": @"1"};
    BOOL isPrivate = [remoteService siteIsPrivateFromPostDictionary:dict];
    XCTAssertTrue(isPrivate, @"Site should be private.");

    dict = @{@"site_is_private": @"0"};
    isPrivate = [remoteService siteIsPrivateFromPostDictionary:dict];
    XCTAssertFalse(isPrivate, @"Site should not be private.");

    dict = [self metaDictionaryWithKey:@"is_private" value:@"1"];
    isPrivate = [remoteService siteIsPrivateFromPostDictionary:dict];
    XCTAssertTrue(isPrivate, @"Meta site should be private.");

    dict = [self metaDictionaryWithKey:@"is_private" value:@"0"];
    isPrivate = [remoteService siteIsPrivateFromPostDictionary:dict];
    XCTAssertFalse(isPrivate, @"Meta site should not be private.");
}

- (void)testSiteURLFromDictionary {
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:nil];

    NSString *site = @"http://site.com";
    NSDictionary *dict = @{@"site_URL": site};
    NSString *siteURL = [remoteService siteURLFromPostDictionary:dict];
    XCTAssertEqual(siteURL, site, @"The returned site did not match what was expected.");

    dict = [self metaDictionaryWithKey:@"URL" value:site];
    siteURL = [remoteService siteURLFromPostDictionary:dict];
    XCTAssertEqual(siteURL, site, @"The returned site did not match what was expected.");
}

- (void)testSiteNameFromDictionary {
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:nil];

    NSString *name = @"foo";
    NSDictionary *dict = @{@"site_name": name};
    NSString *siteName = [remoteService siteNameFromPostDictionary:dict];
    XCTAssertEqual(siteName, name, @"The returned site name did not match what was expected.");

    dict = [self metaDictionaryWithKey:@"name" value:name];
    siteName = [remoteService siteNameFromPostDictionary:dict];
    XCTAssertEqual(siteName, name, @"The returned site name did not match what was expected.");

    dict = [self editorialDictionaryWithKey:@"blog_name" value:name];
    siteName = [remoteService siteNameFromPostDictionary:dict];
    XCTAssertEqual(siteName, name, @"The returned site name did not match what was expected.");

    // Make sure editorial trumps other content.
    NSMutableDictionary *mDict = [dict mutableCopy];
    [mDict setObject:@"bar" forKey:@"site_name"];
    siteName = [remoteService siteNameFromPostDictionary:dict];
    XCTAssertEqual(siteName, name, @"The returned site name did not match what was expected.");

}

- (void)testFeaturedImageFromDictionary {
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:nil];

    NSString *path = @"path.to/image.jpg";
    NSString *uri = [NSString stringWithFormat:@"http://%@", path];
    NSDictionary *dict = @{@"featured_media": @{@"type": @"image", @"uri":uri}};
    NSString *imagePath = [remoteService featuredImageFromPostDictionary:dict];
    XCTAssertTrue([path isEqualToString:imagePath], @"Failed to retrieve the uri for featured media.");

    dict = @{@"featured_media": @{@"type": @"video", @"uri":uri}};
    imagePath = [remoteService featuredImageFromPostDictionary:dict];
    XCTAssertTrue([@"" isEqualToString:imagePath], @"Non image media types should be ignored.");

    dict = [self editorialDictionaryWithKey:@"image" value:uri];
    imagePath = [remoteService featuredImageFromPostDictionary:dict];
    XCTAssertTrue([path isEqualToString:imagePath], @"Failed to retrieve the uri for featured media.");
}

- (void)testSortDateFromDictionary {
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:nil];

    NSString *dateStr = @"foo";
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:dateStr forKey:@"date"];

    NSString *str = [remoteService sortDateFromPostDictionary:dict];
    XCTAssertEqual(dateStr, str, @"Failed to retrieve the correct date.");

    dateStr = @"bar";
    [dict setObject:dateStr forKey:@"date_liked"];
    str = [remoteService sortDateFromPostDictionary:dict];
    XCTAssertEqual(dateStr, str, @"Failed to retrieve the correct date.");

    dateStr = @"baz";
    [dict setObject:@{@"displayed_on":dateStr} forKey:@"editorial"];
    str = [remoteService sortDateFromPostDictionary:dict];
    XCTAssertEqual(dateStr, str, @"Failed to retrieve the correct date.");
}

- (void)testIsWPComFromDictionary {
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:nil];

    NSString *jsonStrFalse = @"{\"is_external\": false}";
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[jsonStrFalse dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    BOOL isWPCom = [remoteService isWPComFromPostDictionary:dict];
    XCTAssertTrue(isWPCom, @"A blog that is not external should be wpcom");

    NSString *jsonStrTrue = @"{\"is_external\": true}";
    dict = [NSJSONSerialization JSONObjectWithData:[jsonStrTrue dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    isWPCom = [remoteService isWPComFromPostDictionary:dict];
    XCTAssertFalse(isWPCom, @"A blog that is external should not be wpcom");

}

- (void)testAuthorEmailFromDictionary {
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:nil];

    NSString *emailStr = @"a@a.aa";
    NSDictionary *dict = @{@"email": emailStr};
    NSString *str = [remoteService authorEmailFromAuthorDictionary:dict];
    XCTAssertEqual(emailStr, str, @"The email returned did not match.");

    emailStr = @"0";
    dict = @{@"email": emailStr};
    str = [remoteService authorEmailFromAuthorDictionary:dict];
    XCTAssertTrue([str length] == 0, @"If the value of email is 0, an empty string should be returned.");
}

- (void)testSanitizeFeaturedImage {
    ReaderPostServiceRemote *remoteService = [[ReaderPostServiceRemote alloc] initWithRemoteApi:nil];

    // Test mshots. Just strips off the query string
    NSString *imagePath = @"https://s0.wp.com/mshots/v1/http%3A%2F%2Fsitename.wordpress.com%2F2013%2F05%2F13%2Fimage%2F?w=252";
    NSString *sanitizedStr = @"https://s0.wp.com/mshots/v1/http%3A%2F%2Fsitename.wordpress.com%2F2013%2F05%2F13%2Fimage%2F";
    NSString *str = [remoteService sanitizeFeaturedImageString:imagePath];
    XCTAssertTrue([str isEqualToString:sanitizedStr], @"Image path returned did not match the path expected.");

    // Test imgpress.
    imagePath = @"https://s0.wp.com/imgpress?resize=252%2C160&url=http%3A%2F%2Fsitename.files.wordpress.com%2F2014%2F04%2Fimage-name.jpg&unsharpmask=80,0.5,3";
    sanitizedStr = @"sitename.files.wordpress.com/2014/04/image-name.jpg";
    str = [remoteService sanitizeFeaturedImageString:imagePath];
    XCTAssertTrue([str isEqualToString:sanitizedStr], @"Image path returned did not match the path expected.");


    // Test normal image path
    imagePath = @"https://sitename.files.wordpress.com/path/to/image.jpg?w=100";
    sanitizedStr = @"sitename.files.wordpress.com/path/to/image.jpg?w=100";
    str = [remoteService sanitizeFeaturedImageString:imagePath];
    XCTAssertTrue([str isEqualToString:sanitizedStr], @"Image path returned did not match the path expected.");
}


#pragma mark - ReaderPostService tests

- (void)testTitleIsPlainText {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    NSString *str = @"Sample text & sample text";

    RemoteReaderPost *remotePost = [[RemoteReaderPost alloc] init];
    remotePost.content = @"";
    remotePost.postTitle = @"<h1>Sample <b>text</b> &amp; sample text</h1>";

    ReaderPost *post = [service createOrReplaceFromRemotePost:remotePost forTopic:nil];
    XCTAssertTrue([str isEqualToString:post.postTitle], @"The post title was not plain text.");
}

- (void)testSummaryIsPlainText {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    NSString *str = @"Sample text & sample text";

    RemoteReaderPost *remotePost = [[RemoteReaderPost alloc] init];
    remotePost.content = @"";
    remotePost.summary = @"<h1>Sample <b>text</b> &amp; sample text</h1>";

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


@end
