#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import <XCTest/XCTest.h>

#import "WPImageSource.h"

@interface WPImageSourceTest : XCTestCase

@end

@implementation WPImageSourceTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testSendTokensToWordPressDotCom
{
    NSString *requestUrl = @"http://test.wordpress.com/images/test-image.jpg";
    NSURL *url = [NSURL URLWithString:requestUrl];
    __block NSString *lastAuthHeader = nil;
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        lastAuthHeader = [request valueForHTTPHeaderField:@"Authorization"];
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"test-image.jpg", [NSBundle bundleForClass:[self class]]) statusCode:200 headers:@{@"Content-Type" : @"image/jpeg"}];
    }];

    WPImageSource *source = [WPImageSource sharedSource];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Download image with token"];

    [source downloadImageForURL:url
                      authToken:@"TOKEN"
                    withSuccess:^(UIImage *image) {
                        [expectation fulfill];
                    } failure:^(NSError *error) {
                        [expectation fulfill];
                        XCTFail();
                    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertEqualObjects(lastAuthHeader, @"Bearer TOKEN");
}

- (void)testDontSendTokensOutsideWordPressDotCom
{
    NSString *requestUrl = @"http://test.blog/images/test-image.jpg";
    NSURL *url = [NSURL URLWithString:requestUrl];
    __block NSString *lastAuthHeader = nil;
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        lastAuthHeader = [request valueForHTTPHeaderField:@"Authorization"];
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"test-image.jpg", [NSBundle bundleForClass:[self class]]) statusCode:200 headers:@{@"Content-Type" : @"image/jpeg"}];
    }];

    WPImageSource *source = [WPImageSource sharedSource];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Download image without token"];
    [source downloadImageForURL:url
                      authToken:@"TOKEN"
                    withSuccess:^(UIImage *image) {
                        [expectation fulfill];
                    } failure:^(NSError *error) {
                        [expectation fulfill];
                        XCTFail();
                    }];

    [self waitForExpectationsWithTimeout:5.0 handler: nil];
    
    XCTAssertNil(lastAuthHeader);
}

- (void)testImagesArentDownloadedTwice
{
    NSString *requestUrl = @"http://test.blog/images/test-image.jpg";
    NSURL *url = [NSURL URLWithString:requestUrl];

    __block int downloadCount = 0;
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] isEqualToString:requestUrl];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        downloadCount++;
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"test-image.jpg", [NSBundle bundleForClass:[self class]]) statusCode:200 headers:@{@"Content-Type" : @"image/jpeg"}];
    }];

    WPImageSource *source = [WPImageSource sharedSource];

    XCTestExpectation *originalDownloadExpectation = [self expectationWithDescription:@"Start 1st download"];
    [source downloadImageForURL:url
                    withSuccess:^(UIImage *image) {
                        [originalDownloadExpectation fulfill];
                    } failure:^(NSError *error) {
                        [originalDownloadExpectation fulfill];
                        XCTFail();
                    }];

    XCTestExpectation *duplicateDownloadExpectation = [self expectationWithDescription:@"Start 1st download"];
    [source downloadImageForURL:url
                    withSuccess:^(UIImage *image) {
                        [duplicateDownloadExpectation fulfill];
                    } failure:^(NSError *error) {
                        [duplicateDownloadExpectation fulfill];
                        XCTFail();
                    }];
    [self waitForExpectationsWithTimeout:5.0 handler: nil];

    XCTAssertEqual(downloadCount, 1, @"it should download the image once");

    XCTestExpectation *anotherDownloadExpectation = [self expectationWithDescription:@"Start 1st download"];
    [source downloadImageForURL:url
                    withSuccess:^(UIImage *image) {
                        [anotherDownloadExpectation fulfill];
                    } failure:^(NSError *error) {
                        [anotherDownloadExpectation fulfill];
                        XCTFail();
                    }];

    [self waitForExpectationsWithTimeout:5.0 handler: nil];
    XCTAssertEqual(downloadCount, 2, @"it should download the image");
}

- (void)testDownloadOfAnimatedGif
{
    NSString *requestUrl = @"http://test.blog/images/anim-reader.gif";
    NSURL *url = [NSURL URLWithString:requestUrl];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"anim-reader.gif", [NSBundle bundleForClass:[self class]]) statusCode:200 headers:@{@"Content-Type" : @"image/gif"}];
    }];

    WPImageSource *source = [WPImageSource sharedSource];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Download image without token"];
    [source downloadImageForURL:url
                      authToken:@"TOKEN"
                    withSuccess:^(UIImage *image) {
                        [expectation fulfill];
                    } failure:^(NSError *error) {
                        [expectation fulfill];
                        XCTFail();
                    }];

    [self waitForExpectationsWithTimeout:5.0 handler: nil];

}

@end
