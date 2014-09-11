#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "WPStatsServiceRemote.h"

@interface WPStatsServiceRemoteTest : XCTestCase
{
    WPStatsServiceRemote *subject;
}

@end

@implementation WPStatsServiceRemoteTest

- (void)setUp
{
    [super setUp];
    subject = [[WPStatsServiceRemote alloc] initWithOAuth2Token:@"token" siteId:@66592863 andSiteTimeZone:[NSTimeZone systemTimeZone]];
}

- (void)tearDown
{
    [super tearDown];
    subject = nil;
}

- (void)testMarshallingMappingHappens
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetch completion"];
    
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
        XCTAssertNotNil(summary, @"summary should not be nil.");
        XCTAssertNotNil(topPosts, @"topPosts should not be nil.");
        XCTAssertNotNil(clicks, @"clicks should not be nil.");
        XCTAssertNotNil(countryViews, @"countryViews should not be nil.");
        XCTAssertNotNil(referrers, @"referrers should not be nil.");
        XCTAssertNotNil(searchTerms, @"searchTerms should not be nil.");
        XCTAssertNotNil(viewsVisitors, @"viewsVisitors should not be nil.");
        
        [expectation fulfill];
    } failureHandler:^(NSError *error) {
        XCTFail(@"Failure handler should not be called here.");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testFetchSummaryStats
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testFetchSummaryStats completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1/batch"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-batch.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [subject fetchSummaryStatsForTodayWithCompletionHandler:^(WPStatsSummary *summary) {
        XCTAssertNotNil(summary, @"summary should not be nil.");
        
        [expectation fulfill];
    } failureHandler:^(NSError *error) {
        XCTFail(@"Failure handler should not be called here.");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
