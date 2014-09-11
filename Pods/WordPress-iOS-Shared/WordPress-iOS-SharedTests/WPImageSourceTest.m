#import <OHHTTPStubs/OHHTTPStubs.h>
#import <XCTest/XCTest.h>
#import "AsyncTestHelper.h"

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
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"test-image.jpg", nil) statusCode:200 headers:@{@"Content-Type" : @"image/jpeg"}];
    }];

    WPImageSource *source = [WPImageSource sharedSource];

    ATHStart();
    [source downloadImageForURL:url
                      authToken:@"TOKEN"
                    withSuccess:^(UIImage *image) {
                        ATHNotify();
                    } failure:^(NSError *error) {
                        XCTFail();
                        ATHNotify();
                    }];
    ATHEnd();

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
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"test-image.jpg", nil) statusCode:200 headers:@{@"Content-Type" : @"image/jpeg"}];
    }];

    WPImageSource *source = [WPImageSource sharedSource];

    ATHStart();
    [source downloadImageForURL:url
                      authToken:@"TOKEN"
                    withSuccess:^(UIImage *image) {
                        ATHNotify();
                    } failure:^(NSError *error) {
                        XCTFail();
                        ATHNotify();
                    }];
    ATHEnd();
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
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"test-image.jpg", nil) statusCode:200 headers:@{@"Content-Type" : @"image/jpeg"}];
    }];

    WPImageSource *source = [WPImageSource sharedSource];

    ATHStart();
    [source downloadImageForURL:url
                    withSuccess:^(UIImage *image) {
                        ATHNotify();
                    } failure:^(NSError *error) {
                        XCTFail();
                        ATHNotify();
                    }];
    [source downloadImageForURL:url
                    withSuccess:^(UIImage *image) {
                        ATHNotify();
                    } failure:^(NSError *error) {
                        XCTFail();
                        ATHNotify();
                    }];
    ATHWait();
    ATHEnd();

    XCTAssertEqual(downloadCount, 1, @"it should download the image once");

    ATHStart();
    [source downloadImageForURL:url
                    withSuccess:^(UIImage *image) {
                        ATHNotify();
                    } failure:^(NSError *error) {
                        XCTFail();
                        ATHNotify();
                    }];
    ATHEnd();
    XCTAssertEqual(downloadCount, 2, @"it should download the image");
}

@end
