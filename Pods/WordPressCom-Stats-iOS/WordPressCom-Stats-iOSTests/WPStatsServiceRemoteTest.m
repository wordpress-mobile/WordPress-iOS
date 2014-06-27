#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "WPStatsServiceRemote.h"
#import "AsyncTestHelper.h"

@interface WPStatsServiceRemoteTest : XCTestCase
{
    WPStatsServiceRemote *subject;
}

@end

@implementation WPStatsServiceRemoteTest

- (void)setUp
{
    [super setUp];
    subject = [[WPStatsServiceRemote alloc] initWithOAuth2Token:@"token" andSiteId:@66592863];
}

- (void)tearDown
{
    [super tearDown];
    subject = nil;
}

- (void)testMarshallingMappingHappens
{
    __block BOOL completionCalled = NO;
    ATHStart();
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1/batch"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-batch.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSDate *today = [formatter dateFromString:@"2014-05-10"];
    NSDate *yesterday = [formatter dateFromString:@"2014-05-09"];
    
    [subject fetchStatsForTodayDate:today andYesterdayDate:yesterday withCompletionHandler:^(WPStatsSummary *summary, NSDictionary *topPosts, NSDictionary *clicks, NSDictionary *countryViews, NSDictionary *referrers, NSDictionary *searchTerms, WPStatsViewsVisitors *viewsVisitors) {
        completionCalled = YES;
        XCTAssertNotNil(summary, @"summary should not be nil.");
        XCTAssertNotNil(topPosts, @"topPosts should not be nil.");
        XCTAssertNotNil(clicks, @"clicks should not be nil.");
        XCTAssertNotNil(countryViews, @"countryViews should not be nil.");
        XCTAssertNotNil(referrers, @"referrers should not be nil.");
        XCTAssertNotNil(searchTerms, @"searchTerms should not be nil.");
        XCTAssertNotNil(viewsVisitors, @"viewsVisitors should not be nil.");
        
        ATHNotify();
    } failureHandler:^(NSError *error) {
        XCTFail(@"Failure handler should not be called here.");
        ATHNotify();
    }];
    
    ATHEnd();
    
    XCTAssertTrue(completionCalled, @"Completion block not called.");
}

@end
