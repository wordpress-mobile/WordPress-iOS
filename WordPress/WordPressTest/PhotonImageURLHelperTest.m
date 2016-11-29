#import <XCTest/XCTest.h>

#import "WordPress-Swift.h"

@interface PhotonImageURLHelperTest : XCTestCase

@end

@implementation PhotonImageURLHelperTest

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

- (void)testPhotonURLForZeroHeight
{
    CGSize size = CGSizeMake(300, 0);
    NSURL *httpsURL = [NSURL URLWithString:@"https://blog.example.com/wp-content/images/image-name.jpg?w=1000"];
    NSURL *photonURL = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:httpsURL];
    NSURL *expected = [NSURL URLWithString:@"https://i0.wp.com/blog.example.com/wp-content/images/image-name.jpg?w=600&ssl=1&quality=80"];
    XCTAssert([photonURL isEqual:expected], @"expected %@ but got %@", expected, photonURL);
}

- (void)testPhotonURLForFit
{
    CGSize size = CGSizeMake(300, 150);
    NSURL *httpsURL = [NSURL URLWithString:@"https://blog.example.com/wp-content/images/image-name.jpg?w=1000"];
    NSURL *photonURL = [WPImageURLHelper photonURLWithSize:size forImageURL:httpsURL forceResize:NO imageQuality:80];
    NSURL *expected = [NSURL URLWithString:@"https://i0.wp.com/blog.example.com/wp-content/images/image-name.jpg?fit=600,300&ssl=1&quality=80"];
    XCTAssert([photonURL isEqual:expected], @"expected %@ but got %@", expected, photonURL);
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

- (void)testPhotonURLForUnacceptableImageType
{
    NSString *baseURL = @"i0.wp.com/path/to/image.tiff";
    CGSize size = CGSizeMake(100, 100);

    NSURL *urlWithScheme = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", baseURL]];
    NSURL *actual = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:urlWithScheme];
    XCTAssert([actual isEqual:urlWithScheme], @"should have returned the same url");

    NSURL *urlWithoutScheme = [NSURL URLWithString:baseURL];
    NSURL *urlWithDefaultScheme = [NSURL URLWithString:[NSString stringWithFormat:@"http:%@", baseURL]];
    actual = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:urlWithoutScheme];
    XCTAssert([actual isEqual:urlWithDefaultScheme], @"should have returned the url prepended with \"http://\"");
}

- (void)testPhotonURLForPhotonURL
{
    CGSize size = CGSizeMake(300, 150);
    NSURL *photonURL = [NSURL URLWithString:@"https://i0.wp.com/blog.example.com/wp-content/images/image-name.jpg"];
    NSURL *actual = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:photonURL];
    XCTAssert([actual isEqual:photonURL], @"should have returned a photon url as-is");
}

- (void)testPhotonURLForPhotonURLWithQueryItems
{
    CGSize size = CGSizeMake(300, 150);
    NSString *photonURLString = @"https://i0.wp.com/blog.example.com/wp-content/images/image-name.jpg?resize=600,300&ssl=1&quality=80";
    NSURL *photonURL = [NSURL URLWithString:photonURLString];
    NSURL *actual = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:photonURL];
    XCTAssert([actual isEqual:photonURL], @"should have returned a photon url as-is");

    NSString *photonInsecureURLString = @"https://i0.wp.com/blog.example.com/wp-content/images/image-name.jpg?resize=600,300&quality=80";
    NSURL *photonInsecureURL = [NSURL URLWithString:photonInsecureURLString];
    actual = [WPImageURLHelper photonDefaultURLWithSize:size forImageURL:photonInsecureURL];
    XCTAssert([actual isEqual:photonInsecureURL], @"should have returned a photon url as-is");
}

@end
