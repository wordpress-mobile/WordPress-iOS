//
//  WPTableImageSourceTest.m
//  WordPress
//
//  Created by Jorge Bernal on 6/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "AsyncTestHelper.h"

#import "WPTableImageSource.h"

static NSString *const requestUrl = @"http://test.blog/images/test-image.jpg";

@interface WPTableImageSourceTest : SenTestCase <WPTableImageSourceDelegate>

@end

@implementation WPTableImageSourceTest {
    WPTableImageSource *_source;
    UIImage *_delegateImage;
    NSIndexPath *_delegateIndexPath;
    int _downloadCount;
    NSURL *_url;
}

- (void)setUp
{
    [super setUp];

    _source = [[WPTableImageSource alloc] initWithMaxSize:CGSizeMake(800, 600)];
    _source.delegate = self;
    _url = [NSURL URLWithString:requestUrl];
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL path] isEqualToString:@"/test.blog/images/test-image.jpg"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        _downloadCount++;
        return [OHHTTPStubsResponse responseWithFile:@"test-image.jpg" contentType:@"image/jpeg" responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [OHHTTPStubs removeAllRequestHandlers];
    _source = nil;
    _delegateIndexPath = nil;
    _delegateImage = nil;
    _downloadCount = 0;
    [super tearDown];
}

- (void)testImageIsDownloadedOnce
{
    ATHStart();
    [_source fetchImageForURL:_url withSize:CGSizeMake(400, 300) indexPath:[NSIndexPath indexPathForRow:1 inSection:0] isPrivate:NO];
    [_source fetchImageForURL:_url withSize:CGSizeMake(300, 200) indexPath:[NSIndexPath indexPathForRow:2 inSection:0] isPrivate:NO];
    ATHWait();
    ATHEnd();
    STAssertEquals(_downloadCount, 1, nil);
}

- (void)testImageIsResized
{
    CGSize wantedSize = CGSizeMake(300, 200);
    ATHStart();
    [_source fetchImageForURL:_url withSize:wantedSize indexPath:[NSIndexPath indexPathForRow:1 inSection:0] isPrivate:NO];
    ATHEnd();
    STAssertNotNil(_delegateImage, nil);
    CGSize size = _delegateImage.size;
    STAssertTrue(CGSizeEqualToSize(size, wantedSize), nil);
}

- (void)testCachedImages
{
    CGSize wantedSize = CGSizeMake(300, 200);
    STAssertNil([_source imageForURL:_url withSize:wantedSize], nil);
    ATHStart();
    [_source fetchImageForURL:_url withSize:wantedSize indexPath:[NSIndexPath indexPathForRow:1 inSection:0] isPrivate:NO];
    ATHEnd();
    STAssertNotNil([_source imageForURL:_url withSize:wantedSize], nil);
    CGSize size = _delegateImage.size;
    STAssertTrue(CGSizeEqualToSize(size, wantedSize), nil);
}

- (void)testResizeImagesSynchronously
{
    CGSize wantedSize = CGSizeMake(300, 200);
    STAssertNil([_source imageForURL:_url withSize:wantedSize], nil);

    ATHStart();
    [_source fetchImageForURL:_url withSize:wantedSize indexPath:[NSIndexPath indexPathForRow:1 inSection:0] isPrivate:NO];
    ATHEnd();

    wantedSize = CGSizeMake(200, 150);
    STAssertNil([_source imageForURL:_url withSize:wantedSize], @"it shouldn't return image if resizing is disabled");

    _source.resizesImagesSynchronously = YES;
    UIImage *image = [_source imageForURL:_url withSize:wantedSize];
    CGSize size = image.size;
    STAssertNotNil(image, @"it should return image if resizing is enabled");
    STAssertEquals(size, wantedSize, @"it should return a correctly sized image");
}

- (void)testInvalidatesIndexPaths
{
    CGSize wantedSize = CGSizeMake(300, 200);
    ATHStart();
    [_source fetchImageForURL:_url withSize:wantedSize indexPath:[NSIndexPath indexPathForRow:1 inSection:0] isPrivate:NO];
    [_source invalidateIndexPaths];
    ATHEndNeverCalled(2);

    STAssertNil(_delegateImage, nil);
    STAssertNil(_delegateIndexPath, nil);
}

- (void)tableImageSource:(WPTableImageSource *)tableImageSource imageReady:(UIImage *)image forIndexPath:(NSIndexPath *)indexPath
{
    _delegateImage = image;
    _delegateIndexPath = indexPath;
    ATHNotify();
}

@end
