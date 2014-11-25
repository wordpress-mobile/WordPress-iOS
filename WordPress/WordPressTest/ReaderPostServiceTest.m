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

@interface ReaderPostServiceTest : XCTestCase

@property (nonatomic, strong) TestContextManager *testContextManager;

@end

@implementation ReaderPostServiceTest

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

#pragma mark - ReaderPostServiceRemote tests

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
    sanitizedStr = @"http://sitename.files.wordpress.com/2014/04/image-name.jpg";
    str = [remoteService sanitizeFeaturedImageString:imagePath];
    XCTAssertTrue([str isEqualToString:sanitizedStr], @"Image path returned did not match the path expected.");


    // Test normal image path
    imagePath = @"https://sitename.files.wordpress.com/path/to/image.jpg?w=100";
    sanitizedStr = @"https://sitename.files.wordpress.com/path/to/image.jpg?w=100";
    str = [remoteService sanitizeFeaturedImageString:imagePath];
    XCTAssertTrue([str isEqualToString:sanitizedStr], @"Image path returned did not match the path expected.");
}


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

- (void)testPostFromPrivateBlogCannotBeReblogged {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    ReaderPostService *service = [[ReaderPostService alloc] initWithManagedObjectContext:context];

    RemoteReaderPost *remotePost = [self remoteReaderPostForTests];
    remotePost.isBlogPrivate = YES;
    ReaderPost *post = [service createOrReplaceFromRemotePost:remotePost forTopic:nil];

    XCTestExpectation *expectation = [self expectationWithDescription:@"reblog expectation"];
    [service reblogPost:post toSite:0 note:nil success:^{
        XCTFail(@"Posts from private blogs should not be rebloggable.");
        [expectation fulfill];
    } failure:^(NSError *error) {
        XCTAssertTrue([error.domain isEqualToString:ReaderPostServiceErrorDomain], @"Reblogging a private post failed but not for the expected reason.");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
