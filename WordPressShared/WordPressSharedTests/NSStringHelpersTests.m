#import <XCTest/XCTest.h>
#import "NSString+Helpers.h"

@interface NSString ()
+ (NSString *)emojiCharacterFromCoreEmojiFilename:(NSString *)filename;
+ (NSString *)emojiFromCoreEmojiImageTag:(NSString *)tag;
@end

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

- (void)testWordCount
{
    NSString *testEmptyPhrase = @"";
    XCTAssert([testEmptyPhrase wordCount] == 0, @"Word count should be zero on a empty string");
    
    NSString *testPhraseEnglish = @"The lazy fox jumped over the fence.";
    XCTAssert([testPhraseEnglish wordCount] == 7, @"Word count should be seven");

    NSString *testPhraseSpanish = @"El zorro perezoso saltó por encima de la valla.";
    XCTAssert([testPhraseSpanish wordCount] == 9, @"Word count should be nine");

    NSString *testPhraseFrench = @"Le renard paresseux sauté par-dessus la clôture.";
    XCTAssert([testPhraseFrench wordCount] == 8, @"Word count should be eight");

    NSString *testPhrasePortuguese = @"A raposa preguiçosa saltou a cerca.";
    XCTAssert([testPhrasePortuguese wordCount] == 6, @"Word count should be six");
}

- (void)testStringByReplacingHTMLEmoticonsWithEmoji
{
    NSString *emoji = @"\U0001F600";
    NSString *imageTag = @"<img src=\"http://s.w.org/images/core/emoji/72x72/1f600.png\" class=\"wp-smiley\" style=\"height: 1em; max-height: 1em;\">";
    NSString *replacedString = [imageTag stringByReplacingHTMLEmoticonsWithEmoji];

    XCTAssert([replacedString isEqualToString:emoji], @"The image tag was not replaced with an emoji string");
}

- (void)testEmojiFromCoreEmojiImageTag
{
    NSString *emoji = @"😜";
    NSString *imageTagTestingAlt = @"<img class=\"emoji\" draggable=\"false\" alt=\"😜\" src=\"http://s.w.org/images/core/emoji/72x72/1f600.png\" scale=\"0\">";
    NSString *imageTagTestingFilename = @"<img class=\"emoji\" draggable=\"false\" src=\"http://s.w.org/images/core/emoji/72x72/1f61c.png\" scale=\"0\">";

    // Test emoji found from alt text
    NSString *str = [NSString emojiFromCoreEmojiImageTag:imageTagTestingAlt];
    XCTAssert([str isEqualToString:emoji], @"The expected emoji was not retrieved from the image tag's alt text");

    // Test emoji found from file path
    str = [NSString emojiFromCoreEmojiImageTag:imageTagTestingFilename];
    XCTAssert([str isEqualToString:emoji], @"The expected emoji was not retrieved from the image tag's  image file name");
}

- (void)testEmojiUnicodeFromCoreEmojiFilename
{
    NSString *copyright = @"A9";
    // Test emoji <= 0xFFFF
    NSString *emojiString = [NSString emojiCharacterFromCoreEmojiFilename:copyright];
    XCTAssert([emojiString isEqualToString:@"\u00A9"], @"The emoji filename was not converted to a unicode code point.");

    NSString *smilingImp = @"1F608";
    // Test emoji > 0xFFFF
    emojiString = [NSString emojiCharacterFromCoreEmojiFilename:smilingImp];
    XCTAssert([emojiString isEqualToString:@"\U0001F608"], @"The emoji filename was not converted to a unicode code point.");

    NSString *flag = @"1f1fa-1f1f8";
    // Test surrogate pair
    emojiString = [NSString emojiCharacterFromCoreEmojiFilename:flag];
    XCTAssert([emojiString isEqualToString:@"\U0001f1fa\U0001f1f8"], @"The emoji filename was not converted to a unicode code point.");

    NSString *invalid = @"ZZZZZ";
    emojiString = [NSString emojiCharacterFromCoreEmojiFilename:invalid];
    XCTAssert([emojiString length] == 0, @"Should return an empty string for an invalid file name.");
}

- (void)testEmojiDoesNotEatUpImages
{
    NSString *emoji = @"\U0001F600";
    NSString *imageTag = @"<img src=\"something.png\"><img src=\"http://s.w.org/images/core/emoji/72x72/1f600.png\" class=\"wp-smiley\" style=\"height: 1em; max-height: 1em;\">";
    NSString *replacedString = [imageTag stringByReplacingHTMLEmoticonsWithEmoji];
    NSString *expected = [@"<img src=\"something.png\">" stringByAppendingString:emoji];

    XCTAssertEqualObjects(expected, replacedString, @"The image tag was not replaced with an emoji string");
}

- (void)testNormalizeWhitespace
{
    NSString *sourceString = @"This     is a \n\n\n test    string.   ";
    NSString *expectedString = @"This is a test string. ";

    XCTAssertTrue([expectedString isEqualToString:[sourceString stringByNormalizingWhitespace]]);
}

@end
