#import <XCTest/XCTest.h>
#import "NSString+Helpers.h"

@interface NSStringHelpersTest : XCTestCase

@end

@implementation NSStringHelpersTest

- (void)testEllipsizing
{
    NSString *sampleText = @"The quick brown fox jumps over the lazy dog.";
    XCTAssertTrue([[sampleText stringByEllipsizingWithMaxLength:14 preserveWords:YES] isEqualToString:@"The quick …"], @"Incorrect Result.");
    XCTAssertTrue([[sampleText stringByEllipsizingWithMaxLength:14 preserveWords:NO] isEqualToString:@"The quick bro…"], @"Incorrect Result.");
    XCTAssertTrue([[sampleText stringByEllipsizingWithMaxLength:100 preserveWords:NO] isEqualToString:sampleText], @"Incorrect Result.");
    XCTAssertTrue([[sampleText stringByEllipsizingWithMaxLength:0 preserveWords:NO] isEqualToString:@""], @"Incorrect Result.");
    
    NSString *url = @"http://www.wordpress.com";
    XCTAssertTrue([[url stringByEllipsizingWithMaxLength:8 preserveWords:YES] isEqualToString:@"http://…"], @"Incorrect Result.");
    
    NSString *longSingleWord = @"ThisIsALongSingleWordThatIsALittleWeird";
    XCTAssertTrue([[longSingleWord stringByEllipsizingWithMaxLength:8 preserveWords:YES] isEqualToString:@"ThisIsA…"], @"Incorrect Result.");
}

- (void)testHostname
{
    NSString *samplePlainURL = @"http://www.wordpress.com";
    NSString *sampleStrippedURL = @"www.wordpress.com";
    XCTAssertEqualObjects(samplePlainURL.hostname, sampleStrippedURL, @"Invalid Stripped String");
    
    NSString *sampleSecureURL = @"https://www.wordpress.com";
    XCTAssertEqualObjects(sampleSecureURL.hostname, sampleStrippedURL, @"Invalid Stripped String");

    NSString *sampleComplexURL = @"http://www.wordpress.com?var=http://wordpress.org";
    XCTAssertEqualObjects(sampleComplexURL.hostname, sampleStrippedURL, @"Invalid Stripped String");
    
    NSString *samplePlainCapsURL = @"http://www.WordPress.com";
    NSString *sampleStrippedCapsURL = @"www.WordPress.com";
    XCTAssertEqualObjects(samplePlainCapsURL.hostname, sampleStrippedCapsURL, @"Invalid Stripped String");
}

- (void)testIsWordPressComPathWithValidDotcomRootPaths
{
    NSArray *validDotcomUrls = @[
        @"http://wordpress.com",
        @"http://www.wordpress.com",
        @"http://www.WordPress.com",
        @"http://www.WordPress.com/",
        @"https://wordpress.com",
        @"https://www.wordpress.com",
        @"https://www.WordPress.com",
        @"https://www.WordPress.com/"
    ];
    
    for (NSString *validDotcomPath in validDotcomUrls) {
        XCTAssertTrue(validDotcomPath.isWordPressComPath, @"Something went wrong. Better call Saul");
    }
}

- (void)testIsWordPressComPathWithInvalidDotcomRootPaths
{
    NSArray *invalidDotcomUrls = @[
        @"http://Zwordpress.com",
        @"http://www.Zwordpress.com",
        @"http://www.ZWordPress.com",
        @"https://Zwordpress.com"
    ];
    
    for (NSString *invalidDotcomPath in invalidDotcomUrls) {
        XCTAssertFalse(invalidDotcomPath.isWordPressComPath, @"Something went wrong. Better call Saul");
    }
}

- (void)testIsWordPressComPathWithMissingProtocol
{
    NSArray *validDotcomUrls = @[
        @"wordpress.com",
        @"wordpress.com/something",
        @"www.wordpress.com",
        @"www.WordPress.com",
        @"www.WordPress.com/something",
    ];
    
    for (NSString *validDotcomPath in validDotcomUrls) {
        XCTAssertTrue(validDotcomPath.isWordPressComPath, @"Something went wrong. Better call Saul");
    }
}

- (void)testIsWordPressComPathWithValidPathsWithSubdomains
{
    NSArray *validDotcomUrls = @[
        @"http://blog.wordpress.com",
        @"http://blog.WordPress.com",
        @"https://blog.wordpress.com",
        @"https://blog.WordPress.com",
        @"http://blog.WordPress.com/some",
        @"http://blog.WordPress.com/some/thing/else"
    ];
    
    for (NSString *validDotcomPath in validDotcomUrls) {
        XCTAssertTrue(validDotcomPath.isWordPressComPath, @"Something went wrong. Better call Saul");
    }
}

- (void)testIsWordPressComPathWithInvalidProtocols
{
    NSArray *invalidDotcomUrls = @[
        @"hppt://wordpress.com",
        @"httpz://www.wordpress.com",
        @"httpsz://www.WordPress.com",
        @"zzzzzz://wordpress.com"
    ];
    
    for (NSString *invalidDotcomPath in invalidDotcomUrls) {
        XCTAssertFalse(invalidDotcomPath.isWordPressComPath, @"Something went wrong. Better call Saul");
    }
}

@end
