#import "ContextManager.h"
#import "WPAccount.h"
#import "ReaderTopicService.h"
#import "ReaderTopicServiceRemote.h"
#import "RemoteReaderTopic.h"
#import "ReaderPost.h"
#import "ReaderPostService.h"
#import "ReaderPostServiceRemote.h"
#import "RemoteReaderPost.h"
#import <XCTest/XCTest.h>
#import "TestContextManager.h"

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
- (NSDictionary *)primaryAndSecondaryTagsFromPostDictionary:(NSDictionary *)dict;
- (NSNumber *)readingTimeForWordCount:(NSNumber *)wordCount;

@end


@interface ReaderPostServiceRemoteTests : XCTestCase
@end

@implementation ReaderPostServiceRemoteTests


#pragma mark - Configuration

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

- (NSDictionary *)tagDictionaryWithName:(NSString *)name slug:(NSString *)slug postCount:(NSNumber *)postCount
{
    return @{
             @"name":name,
             @"slug":slug,
             @"post_count":postCount
             };
}

- (NSDictionary *)demoTagDictionary
{
    NSDictionary *tags = @{
                           @"fake":[self tagDictionaryWithName:@"Fake" slug:@"fake" postCount:@(1)],
                           @"primary":[self tagDictionaryWithName:@"Primary" slug:@"primary" postCount:@(10)],
                           @"secondary":[self tagDictionaryWithName:@"Secondary" slug:@"secondary" postCount:@(9)],
                           @"fake":[self tagDictionaryWithName:@"Fake" slug:@"fake" postCount:@(5)],
                           @"fake":[self tagDictionaryWithName:@"Fake" slug:@"fake" postCount:@(3)],
                           };
    return @{@"tags":tags};
}

- (NSDictionary *)demoTagsAndEditorialDictionary
{
    NSDictionary *editorial = @{
                                @"highlight_topic_title":@"Editorial",
                                @"highlight_topic":@"editorial"
                                };
    NSMutableDictionary *mdict = [[self demoTagDictionary] mutableCopy];
    [mdict setObject:editorial forKey:@"editorial"];

    return [mdict copy];
}

#pragma mark - Common

/**
 *  @brief      Common method for instantiating and initializing the service object.
 *  @details    This is only useful for cases that don't need to mock the API object.
 *
 *  @returns    The newly created service object.
 */
- (ReaderPostServiceRemote*)service
{
    WordPressComApi *api = [[WordPressComApi alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    return [[ReaderPostServiceRemote alloc] initWithApi:api];
}

#pragma mark - ReaderPostServiceRemote tests

- (void)testSiteIsPrivate {
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

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
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

    NSString *site = @"http://site.com";
    NSDictionary *dict = @{@"site_URL": site};
    NSString *siteURL = [remoteService siteURLFromPostDictionary:dict];
    XCTAssertEqual(siteURL, site, @"The returned site did not match what was expected.");

    dict = [self metaDictionaryWithKey:@"URL" value:site];
    siteURL = [remoteService siteURLFromPostDictionary:dict];
    XCTAssertEqual(siteURL, site, @"The returned site did not match what was expected.");
}

- (void)testSiteNameFromDictionary {
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

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
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

    NSString *path = @"path.to/image.jpg";
    NSString *uri = [NSString stringWithFormat:@"http://%@", path];
    NSDictionary *dict = @{@"featured_image": uri};
    NSString *imagePath = [remoteService featuredImageFromPostDictionary:dict];
    XCTAssertTrue([uri isEqualToString:imagePath], @"Failed to retrieve the uri for featured media.");

    dict = @{@"featured_media": @{@"type": @"video", @"uri":uri}};
    imagePath = [remoteService featuredImageFromPostDictionary:dict];
    XCTAssertTrue([@"" isEqualToString:imagePath], @"Non image media types should be ignored.");

    dict = @{@"attachments": @{@"111": @{@"mime_type": @"image/jpg", @"width":@(2048), @"URL":uri}}};
    imagePath = [remoteService featuredImageFromPostDictionary:dict];
    XCTAssertTrue([uri isEqualToString:imagePath], @"Failed to retrieve the uri from attachments.");

    dict = [self editorialDictionaryWithKey:@"image" value:uri];
    imagePath = [remoteService featuredImageFromPostDictionary:dict];
    XCTAssertTrue([uri isEqualToString:imagePath], @"Failed to retrieve the uri for featured media.");
}

- (void)testSortDateFromDictionary {
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

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
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

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
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

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
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

    // Test mshots. Just strips off the query string
    NSString *imagePath = @"https://s0.wp.com/mshots/v1/http%3A%2F%2Fsitename.wordpress.com%2F2013%2F05%2F13%2Fimage%2F?w=252";
    NSString *sanitizedStr = @"https://s0.wp.com/mshots/v1/http%3A%2F%2Fsitename.wordpress.com%2F2013%2F05%2F13%2Fimage%2F";
    NSString *str = [remoteService sanitizeFeaturedImageString:imagePath];
    XCTAssertTrue([str isEqualToString:sanitizedStr], @"Image path returned did not match the path expected.");

    // Test imgpress.
    imagePath = @"https://s0.wp.com/imgpress?resize=252%2C160&url=http%3A%2F%2Fsitename.files.wordpress.com%2F2014%2F04%2Fimage-name.jpg&unsharpmask=80,0.5,3";
    sanitizedStr = @"http://sitename.files.wordpress.com/2014/04/image-name.jpg";
    str = [remoteService sanitizeFeaturedImageString:imagePath];
    XCTAssertTrue([str isEqualToString:sanitizedStr], @"Image path returned did not match the path expected.");


    // Test normal image path
    imagePath = @"https://sitename.files.wordpress.com/path/to/image.jpg?w=100";
    sanitizedStr = @"https://sitename.files.wordpress.com/path/to/image.jpg?w=100";
    str = [remoteService sanitizeFeaturedImageString:imagePath];
    XCTAssertTrue([str isEqualToString:sanitizedStr], @"Image path returned did not match the path expected.");
}

- (void)testNoTagsFromDictionary
{
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

    NSDictionary *demoTags = @{@"tags":@{}};
    NSDictionary *tags = [remoteService primaryAndSecondaryTagsFromPostDictionary:demoTags];

    for (NSString *value in [tags allValues]) {
        XCTAssertTrue([value length] == 0, @"All values should be empty in the returned dictionary.");
    }
}

- (void)testPrimaryTagFromDictionary
{
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);


    NSDictionary *demoTags  = @{@"tags": @{
                                        @"Primary":[self tagDictionaryWithName:@"Primary" slug:@"primary" postCount:@3]
                                        }
                                };
    NSDictionary *tags = [remoteService primaryAndSecondaryTagsFromPostDictionary:demoTags];
    XCTAssertTrue([[tags objectForKey:@"primaryTag"] isEqualToString:@"Primary"], @"Primary tag should have the highest post count");
    XCTAssertTrue([[tags objectForKey:@"secondaryTag"] isEqualToString:@""], @"Secondary tag should be an empty string");
}

- (void)testPrimaryAndSecondaryTagsFromDictionary
{
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

    NSDictionary *demoTags = [self demoTagDictionary];
    NSDictionary *tags = [remoteService primaryAndSecondaryTagsFromPostDictionary:demoTags];

    XCTAssertTrue([[tags objectForKey:@"primaryTag"] isEqualToString:@"Primary"], @"Primary tag should have the highest post count");
    XCTAssertTrue([[tags objectForKey:@"secondaryTag"] isEqualToString:@"Secondary"], @"Secondary tag should have the second highest post count");
}

- (void)testEditorialTagsFromDictionary
{
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

    NSDictionary *demoTags = [self demoTagsAndEditorialDictionary];
    NSDictionary *tags = [remoteService primaryAndSecondaryTagsFromPostDictionary:demoTags];

    XCTAssertTrue([[tags objectForKey:@"primaryTag"] isEqualToString:@"Editorial"], @"Primary tag should be editorial defined");
    XCTAssertTrue([[tags objectForKey:@"secondaryTag"] isEqualToString:@"Primary"], @"Secondary tag should have the highest post count");
}

- (void)testReadingTimeFromDictionary
{
    ReaderPostServiceRemote *remoteService = nil;
    XCTAssertNoThrow(remoteService = [self service]);

    NSNumber *readingTime;
    readingTime = [remoteService readingTimeForWordCount:@0];
    XCTAssertTrue([readingTime integerValue] == 0, @"Zero wordcount should return zero reading time.");

    readingTime = [remoteService readingTimeForWordCount:@250];
    XCTAssertTrue([readingTime integerValue] == 0, @"Brief word count should return zero reading time.");

    readingTime = [remoteService readingTimeForWordCount:@500];
    XCTAssertTrue([readingTime integerValue] == 2, @"500 words should take about 2 minutes to read");

    readingTime = [remoteService readingTimeForWordCount:@700];
    XCTAssertTrue([readingTime integerValue] == 2, @"700 words should take about 2 minutes to read.");
    
    readingTime = [remoteService readingTimeForWordCount:@1000];
    XCTAssertTrue([readingTime integerValue] == 4, @"1000 words should take about 4 minutes to read");
}

@end
