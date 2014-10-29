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
    
    NSString *foreignLanguage = @"わたしはいぬがすきです";
    XCTAssertTrue([[foreignLanguage stringByEllipsizingWithMaxLength:4 preserveWords:YES] isEqualToString:@"わたし…"], @"Incorrect Result.");
    
    NSString *url = @"http://www.wordpress.com";
    XCTAssertTrue([[url stringByEllipsizingWithMaxLength:8 preserveWords:YES] isEqualToString:@"http://…"], @"Incorrect Result.");
    
    NSString *longSingleWord = @"ThisIsALongSingleWordThatIsALittleWeird";
    XCTAssertTrue([[longSingleWord stringByEllipsizingWithMaxLength:8 preserveWords:YES] isEqualToString:@"ThisIsA…"], @"Incorrect Result.");
}

- (void)testStrippingProtocol
{
    NSString *samplePlainURL = @"http://www.wordpress.com";
    NSString *sampleStrippedURL = @"www.wordpress.com";
    XCTAssertEqualObjects(samplePlainURL.stringByStrippingProtocol, sampleStrippedURL, @"Invalid Stripped String");
    
    NSString *sampleSecureURL = @"https://www.wordpress.com";
    XCTAssertEqualObjects(sampleSecureURL.stringByStrippingProtocol, sampleStrippedURL, @"Invalid Stripped String");
    
    NSString *samplePlainCapsdURL = @"http://www.WordPress.com";
    NSString *sampleStrippedCapsURL = @"www.WordPress.com";
    XCTAssertEqualObjects(samplePlainCapsdURL.stringByStrippingProtocol, sampleStrippedCapsURL, @"Invalid Stripped String");
}

@end
