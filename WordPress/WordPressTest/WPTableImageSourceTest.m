#import <XCTest/XCTest.h>
#import "WPTableImageSource.h"

@interface WPTableImageSource()
- (NSURL *)photonURLForURL:(NSURL *)url withSize:(CGSize)size;
@end

@interface WPTableImageSourceTest : XCTestCase
@property (nonatomic, strong) WPTableImageSource *source;
@end

@implementation WPTableImageSourceTest
- (void)setUp
{
    [super setUp];
    self.source = [[WPTableImageSource alloc] initWithMaxSize:CGSizeZero];
}

- (void)tearDown
{
    self.source = nil;

    [super tearDown];
}

- (void)testPhotonURLForURLSupportsHTTPS
{
    // arbitrary size
    CGSize size = CGSizeMake(300, 150);
    NSURL *photonURL;
    NSString *domainPathQueryStringForImage = @"blog.example.com/wp-content/images/image-name.jpg?w=1000";

    NSURL *httpsURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", domainPathQueryStringForImage]];
    photonURL = [self.source photonURLForURL:httpsURL withSize:size];
    XCTAssertNotNil(photonURL, @"A valid URL should be returned, got nil instead.");
    XCTAssertTrue([[photonURL host] isEqualToString:@"i0.wp.com"], @"A Photon URL should be returned, a url with a different host was returned instead.");
    XCTAssertTrue(([[photonURL query] rangeOfString:@"&ssl=1"].location != NSNotFound), @"The Photon URL should be formatted for ssl.");

    NSURL *httpURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", domainPathQueryStringForImage]];
    photonURL = [self.source photonURLForURL:httpURL withSize:size];
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
    NSURL *photonURL = [self.source photonURLForURL:url withSize:size];

    XCTAssertTrue([[photonURL absoluteString] isEqualToString:path]);
}

@end
