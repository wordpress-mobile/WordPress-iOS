#import <XCTest/XCTest.h>

#import "WordPress-Swift.h"

@interface PhotonImageURLHelperTest : XCTestCase

@end

@implementation PhotonImageURLHelperTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testPhotonURLForURLSupportsHTTPS
{
    // arbitrary size
    CGSize size = CGSizeMake(300, 150);
    NSURL *photonURL;
    NSString *domainPathQueryStringForImage = @"blog.example.com/wp-content/images/image-name.jpg?w=1000";

    NSURL *httpsURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", domainPathQueryStringForImage]];
    photonURL = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:httpsURL];
    XCTAssertNotNil(photonURL, @"A valid URL should be returned, got nil instead.");
    XCTAssertTrue([[photonURL host] isEqualToString:@"i0.wp.com"], @"A Photon URL should be returned, a url with a different host was returned instead.");
    XCTAssertTrue(([[photonURL query] rangeOfString:@"&ssl=1"].location != NSNotFound), @"The Photon URL should be formatted for ssl.");

    NSURL *httpURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", domainPathQueryStringForImage]];
    photonURL = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:httpURL];
    XCTAssertNotNil(photonURL, @"A valid URL should be returned, got nil instead.");
    XCTAssertTrue([[photonURL host] isEqualToString:@"i0.wp.com"], @"A Photon URL should be returned, a url with a different host was returned instead.");
    XCTAssertFalse(([[photonURL query] rangeOfString:@"&ssl=1"].location != NSNotFound), @"The Photon URL should not be formatted for ssl.");
}

- (void)testPhotonMShotURL
{
    // arbitrary size
    CGSize size = CGSizeMake(300, 150);
    NSString *basePath = @"https://blog.example.com/mshots/wp-content/images/image-name.jpg";
    NSString *query = @"?w=1000";
    NSString *domainPathQueryStringForImage = [NSString stringWithFormat:@"%@%@", basePath, query];
    NSURL *photonURL = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:[NSURL URLWithString:domainPathQueryStringForImage]];

    XCTAssert([photonURL.absoluteString containsString:basePath], @"expected \"%@\" to contain the substring \"%@\"", photonURL.absoluteString, basePath);
    XCTAssert([[photonURL.absoluteString stringByReplacingOccurrencesOfString:basePath withString:@""] isEqualToString:@"?w=300&h=150"]);
}

- (void)testPhotonURLReturnsUnChanged
{
    // arbitrary size
    CGSize size = CGSizeMake(300, 150);
    NSArray<NSString *> *paths = @[
                                   @"https://i0.wp.com/path/to/image.jpg",
                                   @"https://i1.wp.com/path/to/image.jpg",
                                   @"https://i2.wp.com/path/to/image.jpg"
                                   ];
    for (NSString *path in paths) {
        NSURL *url = [NSURL URLWithString:path];
        NSURL *photonURL = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:url];

        XCTAssertTrue([[photonURL absoluteString] isEqualToString:path], @"expected %@ but got %@", path, [photonURL absoluteString]);
    }
}

@end
