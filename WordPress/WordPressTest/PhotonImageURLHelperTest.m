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
    NSString *domainPathQueryStringForImage = @"https://blog.example.com/mshots/wp-content/images/image-name.jpg?w=1000";
    NSURL *photonURL = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:[NSURL URLWithString:domainPathQueryStringForImage]];

    // FIXME: there are several bugs in the mshots codepath that will be fixed in a later commit:
    // - should have a scheme
    // - should not append a query string after the existing query string
    // - the width and height parameter values in the url string seem to be accidentally computed with the value of a pointer location: it changes every run of the test
    NSString *expectedString = @"blog.example.com/mshots/wp-content/images/image-name.jpg?w=";
    XCTAssert([photonURL.absoluteString containsString:expectedString], @"expected \"%@\" to contain the substring \"%@\"", photonURL.absoluteString, expectedString);
    XCTAssertFalse([photonURL.absoluteString containsString:@"http"]);
    XCTAssert([[photonURL.absoluteString stringByReplacingOccurrencesOfString:expectedString withString:@""] containsString:@"?w="]);
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
