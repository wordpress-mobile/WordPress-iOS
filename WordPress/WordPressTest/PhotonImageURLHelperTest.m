#import <XCTest/XCTest.h>
#import "PhotonImageURLHelper.h"


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
    photonURL = [PhotonImageURLHelper photonURLWithSize:size forImageURL:httpsURL];
    XCTAssertNotNil(photonURL, @"A valid URL should be returned, got nil instead.");
    XCTAssertTrue([[photonURL host] isEqualToString:@"i0.wp.com"], @"A Photon URL should be returned, a url with a different host was returned instead.");
    XCTAssertTrue(([[photonURL query] rangeOfString:@"&ssl=1"].location != NSNotFound), @"The Photon URL should be formatted for ssl.");

    NSURL *httpURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", domainPathQueryStringForImage]];
    photonURL = [PhotonImageURLHelper photonURLWithSize:size forImageURL:httpURL];
    XCTAssertNotNil(photonURL, @"A valid URL should be returned, got nil instead.");
    XCTAssertTrue([[photonURL host] isEqualToString:@"i0.wp.com"], @"A Photon URL should be returned, a url with a different host was returned instead.");
    XCTAssertFalse(([[photonURL query] rangeOfString:@"&ssl=1"].location != NSNotFound), @"The Photon URL should not be formatted for ssl.");
}

- (void)testPhotonURLReturnsUnChanged
{
    // arbitrary size
    CGSize size = CGSizeMake(300, 150);
    NSString *path = @"https://i0.wp.com/path/to/image.jpg";
    NSURL *url = [NSURL URLWithString:path];
    NSURL *photonURL = [PhotonImageURLHelper photonURLWithSize:size forImageURL:url];

    XCTAssertTrue([[photonURL absoluteString] isEqualToString:path]);
}

@end
