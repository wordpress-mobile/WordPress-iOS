//
//  WPAvatarSourceTest.m
//  WordPress
//
//  Created by Jorge Bernal on 6/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "AsyncTestHelper.h"
#import <MGImageUtilities/UIImage+ProportionalFill.h>

#import "WPAvatarSource.h"

@interface WPAvatarSourceTest : SenTestCase

@end

@implementation WPAvatarSourceTest {
    WPAvatarSource *_source;
}

- (void)setUp
{
    [super setUp];

    _source = [WPAvatarSource sharedSource];
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL host] isEqualToString:@"gravatar.com"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFile:@"misteryman.jpg" contentType:@"image/jpeg" responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
}

- (void)tearDown
{
    _source = nil;
    [_source performSelector:@selector(purgeCaches)];
    [OHHTTPStubs removeAllRequestHandlers];

    [super tearDown];
}

- (void)testGravatarCaches
{
    NSString *email = @"test1@test.blog";
    CGSize size = CGSizeMake(48, 48);
    UIImage *image = [_source cachedImageForGravatarEmail:email withSize:size];
    STAssertNil(image, @"cache should be empty");

    ATHStart();
    [_source fetchImageForGravatarEmail:email withSize:size success:^(UIImage *image) {
        STAssertNotNil(image, @"avatar should be downloaded");
        STAssertEquals(image.size.width, 48.f, @"avatar should be resized");
        ATHNotify();
    }];
    ATHEnd();

    image = [_source cachedImageForGravatarEmail:email withSize:size];
    STAssertNotNil(image, @"avatar should be in cache");
    STAssertEquals(image.size.width, 48.f, @"cached avatar should be the requested size");

    size = CGSizeMake(32, 32);
    image = [_source cachedImageForGravatarEmail:email withSize:size];
    STAssertNil(image, @"cached avatar shouldn't resize on the fly");

    _source.resizesSynchronously = YES;
    image = [_source cachedImageForGravatarEmail:email withSize:size];
    STAssertNotNil(image, @"cached avatar should resize on the fly");
    STAssertEquals(image.size.width, 32.f, @"cached avatar should be the requested size");
    _source.resizesSynchronously = NO;
}

- (void)testParseUrls
{
    NSString *hash;
    WPAvatarSourceType sourceType;
    NSURL *url;

    url = [NSURL URLWithString:@"https://1.gravatar.com/avatar/767fc9c115a1b989744c755db47feb60?s=100&d=https%3A%2F%2Fsecure.gravatar.com%2Fblavatar%2F1dda380e30f5105e49d00ff16adc24a4%3Fs%3D100%26d%3Dhttps%253A%252F%252Fs2.wp.com%252Fwp-content%252Fthemes%252Fh4%252Ftabs%252Fimages%252Fdefaultavatar.png&r=G"];
    sourceType = [_source parseURL:url forAvatarHash:&hash];
    STAssertEquals(sourceType, WPAvatarSourceTypeGravatar, nil);
    STAssertEqualObjects(hash, @"767fc9c115a1b989744c755db47feb60", nil);

    url = [NSURL URLWithString:@"http://0.gravatar.com/blavatar/64a3dabbcfffcf6e9a41e4ea19c8bf20?s=32"];
    sourceType = [_source parseURL:url forAvatarHash:&hash];
    STAssertEquals(sourceType, WPAvatarSourceTypeBlavatar, nil);
    STAssertEqualObjects(hash, @"64a3dabbcfffcf6e9a41e4ea19c8bf20", nil);

    url = [NSURL URLWithString:@"https://s2.wp.com/wp-content/themes/h4/tabs/images/defaultavatar.png"];
    sourceType = [_source parseURL:url forAvatarHash:&hash];
    STAssertEquals(sourceType, WPAvatarSourceTypeUnknown, nil);
}

@end
