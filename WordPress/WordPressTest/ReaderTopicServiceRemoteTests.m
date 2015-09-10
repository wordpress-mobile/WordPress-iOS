#import <XCTest/XCTest.h>

#import "ReaderTopicServiceRemote.h"
#import "RemoteReaderTopic.h"
#import "WordPressComApi.h"

@interface ReaderTopicServiceRemote()
- (RemoteReaderTopic *)normalizeTopicDictionary:(NSDictionary *)topicDict subscribed:(BOOL)subscribed recommended:(BOOL)recommended;
@end

@interface ReaderTopicServiceRemoteTests : XCTestCase
@end

@implementation ReaderTopicServiceRemoteTests

- (void)setUp {
    [super setUp];

}

- (void)tearDown {
    [super tearDown];
}


#pragma mark - Common

/**
 *  @brief      Common method for instantiating and initializing the service object.
 *  @details    This is only useful for cases that don't need to mock the API object.
 *
 *  @returns    The newly created service object.
 */
- (ReaderTopicServiceRemote *)service
{
    WordPressComApi *api = [[WordPressComApi alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    return [[ReaderTopicServiceRemote alloc] initWithApi:api];
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

    ReaderTopicServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

    RemoteReaderTopic *remoteTopic = [remoteService normalizeTopicDictionary:topicDictionaryWithID subscribed:YES recommended:YES];
    XCTAssertTrue(remoteTopic.isRecommended, @"Remote topic should be recommended but wasn't.");
    XCTAssertTrue(remoteTopic.isSubscribed, @"Remote topic should be subscribed but wasn't.");
    XCTAssertTrue([remoteTopic.path isEqualToString:topicDictionaryWithID[@"URL"]], @"Remote topic path did not match.");
    XCTAssertEqual(remoteTopic.title, topicDictionaryWithID[@"title"], @"Remote topic title did not match.");
    XCTAssertEqual([remoteTopic.topicID integerValue], [topicDictionaryWithID[@"ID"] integerValue], @"Remote topic ID did not match.");

    remoteTopic = [remoteService normalizeTopicDictionary:topicDictionaryWithoutID subscribed:NO recommended:NO];
    XCTAssertFalse(remoteTopic.isRecommended, @"Remote topic should not be recommended but was.");
    XCTAssertFalse(remoteTopic.isSubscribed, @"Remote topic should not be subscribed but was.");
    XCTAssertTrue([remoteTopic.path isEqualToString:topicDictionaryWithID[@"URL"]], @"Remote topic path did not match.");
    XCTAssertEqual(remoteTopic.title, topicDictionaryWithID[@"title"], @"Remote topic title did not match.");
    XCTAssertEqual(remoteTopic.topicID, @0, @"Remote topic ID was not 0.");
}

@end
