//
//  WPImageSourceTest.m
//  WordPress
//
//  Created by Jorge Bernal on 6/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <OHHTTPStubs/OHHTTPStubs.h>
#import <SenTestingKit/SenTestingKit.h>
#import "AsyncTestHelper.h"

#import "WPImageSource.h"

@interface WPImageSourceTest : SenTestCase

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

- (void)testImagesArentDownloadedTwice
{
    NSString *requestUrl = @"http://test.blog/images/test-image.jpg";
    NSURL *url = [NSURL URLWithString:requestUrl];

    __block int downloadCount = 0;
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] isEqualToString:requestUrl];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        downloadCount++;
        return [OHHTTPStubsResponse responseWithFile:@"test-image.jpg" contentType:@"image/jpeg" responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];

    WPImageSource *source = [WPImageSource sharedSource];

    ATHStart();
    [source downloadImageForURL:url
                    withSuccess:^(UIImage *image) {
                        ATHNotify();
                    } failure:^(NSError *error) {
                        STFail(nil);
                        ATHNotify();
                    }];
    [source downloadImageForURL:url
                    withSuccess:^(UIImage *image) {
                        ATHNotify();
                    } failure:^(NSError *error) {
                        STFail(nil);
                        ATHNotify();
                    }];
    ATHWait();
    ATHEnd();

    STAssertEquals(downloadCount, 1, @"it should download the image once");

    ATHStart();
    [source downloadImageForURL:url
                    withSuccess:^(UIImage *image) {
                        ATHNotify();
                    } failure:^(NSError *error) {
                        STFail(nil);
                        ATHNotify();
                    }];
    ATHEnd();
    STAssertEquals(downloadCount, 2, @"it should download the image");
}

@end
