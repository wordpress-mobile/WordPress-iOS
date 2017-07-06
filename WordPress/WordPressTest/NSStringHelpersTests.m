#import <XCTest/XCTest.h>

@interface NSStringHelpersTest : XCTestCase

@end

@implementation NSStringHelpersTest

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

- (void)testUniqueStringComponentsSeparatedByWhitespaceCorrectlyReturnsASetWithItsWords
{
    NSString *testString = @"first\nsecond third\nfourth fifth";
    NSSet *testSet = [testString uniqueStringComponentsSeparatedByNewline];
    XCTAssert([testSet containsObject:@"first"], @"Missing line");
    XCTAssert([testSet containsObject:@"second third"], @"Missing line");
    XCTAssert([testSet containsObject:@"fourth fifth"], @"Missing line");
    XCTAssert([testSet count] == 3, @"Invalid count");
}

- (void)testUniqueStringComponentsSeparatedByWhitespaceDoesntAddEmptyStrings
{
    NSString *testString = @"";
    NSSet *testSet = [testString uniqueStringComponentsSeparatedByNewline];
    XCTAssert([testSet count] == 0, @"Invalid count");
}

- (void)testIsValidEmail
{
    // Although rare, TLDs can have email too
    XCTAssertTrue([@"koke@com" isValidEmail]);
    
    // Unusual but valid!
    XCTAssertTrue([@"\"Jorge Bernal\"@example.com" isValidEmail]);
    
    // The hyphen is permitted if it is surrounded by characters, digits or hyphens,
    // although it is not to start or end a label
    XCTAssertTrue([@"koke@-example.com" isValidEmail]);
    XCTAssertTrue([@"koke@example-.com" isValidEmail]);
    
    // https://en.wikipedia.org/wiki/International_email
    XCTAssertTrue([@"用户@例子.广告" isValidEmail]);
    XCTAssertTrue([@"उपयोगकर्ता@उदाहरण.कॉम" isValidEmail]);
    
    // Now, the invalid scenario
    XCTAssertFalse([@"notavalid.email" isValidEmail]);
}

@end
