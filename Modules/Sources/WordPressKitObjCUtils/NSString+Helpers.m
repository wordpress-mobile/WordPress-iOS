#import "NSString+Helpers.h"
#import <CommonCrypto/CommonDigest.h>
#import "NSString+XMLExtensions.h"

static NSString *const Ellipsis =  @"\u2026";

@implementation NSString (WPKitHelpers)

#pragma mark Helpers

/**
 Parses an WordPress core emoji IMG tag and returns the corresponding emoji character.
 */
+ (NSString *)emojiFromCoreEmojiImageTag:(NSString *)tag
{
    if ([tag rangeOfString:@"<img"].location == NSNotFound || [tag rangeOfString:@"/images/core/emoji/"].location == NSNotFound) {
        return nil;
    }

    static NSRegularExpression *altRegex;
    static NSRegularExpression *filenameRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        altRegex = [NSRegularExpression regularExpressionWithPattern:@" alt=['\"]([^'\"]+)['\"]" options:NSRegularExpressionCaseInsensitive error:&error];
        filenameRegex = [NSRegularExpression regularExpressionWithPattern:@"/images/core/emoji/[^/]+/(.+?).png" options:NSRegularExpressionCaseInsensitive error:&error];
    });

    // Check for the alt tag first as it should be the unicode emoji character.
    NSRange sourceRange = NSMakeRange(0, [tag length]);
    NSArray *matches = [altRegex matchesInString:tag options:0 range:sourceRange];
    if ([matches count] > 0) {
        NSTextCheckingResult *match = [matches firstObject];
        if (match.numberOfRanges == 2) {
            NSRange range = [match rangeAtIndex:1];
            return [tag substringWithRange:range];
        }
    }

    matches = [filenameRegex matchesInString:tag options:0 range:sourceRange];
    if ([matches count] > 0) {
        NSTextCheckingResult *match = [matches firstObject];
        if (match.numberOfRanges == 2) {
            NSRange range = [match rangeAtIndex:1];
            NSString *filename = [tag substringWithRange:range];
            return [self emojiCharacterFromCoreEmojiFilename:filename];
        }
    }

    return nil;
}

/**
 Processes the filename of an core emoji image from `s.w.org/images/core/emoji`
 and returns the unicode character for the emoji.
 Filenames can be formatted as a single hex value, or for emoji comprised of
 Unicode pairs, as two hex values separated by a dash.
 */
+ (NSString *)emojiCharacterFromCoreEmojiFilename:(NSString *)filename
{
    NSArray *components = [filename componentsSeparatedByString:@"-"];
    NSMutableArray *marr = [NSMutableArray array];
    for (NSString *string in components) {
        NSString *unicodeChar = [NSString unicodeCharacterFromHexString:string];
        if (unicodeChar) {
            [marr addObject:unicodeChar];
        }
    }

    return [marr componentsJoinedByString:@""];
}

+ (NSString *)unicodeCharacterFromHexString:(NSString *)hexString
{
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    unsigned long long hex = 0;
    BOOL success = [scanner scanHexLongLong:&hex];
    if (!success) {
        return nil;
    }
    return [[NSString alloc] initWithBytes:&hex length:4 encoding:NSUTF32LittleEndianStringEncoding];
}

// Taken from AFNetworking's AFPercentEscapedQueryStringPairMemberFromStringWithEncoding
- (NSString *)wpkit_stringByUrlEncoding
{
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    NSString *charactersToLeaveUnescaped = @"[].";
    [allowedCharacterSet addCharactersInString:charactersToLeaveUnescaped];
    return [self stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
}

/*
 * Uses a RegEx to strip all HTML tags from a string and unencode entites
 */
- (NSString *)wpkit_stringByStrippingHTML
{
    return [self stringByReplacingOccurrencesOfString:@"<[^>]+>" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, self.length)];
}

// A method to truncate a string at a predetermined length and append ellipsis to the end

- (NSString *)wpkit_stringByEllipsizingWithMaxLength:(NSInteger)lengthlimit preserveWords:(BOOL)preserveWords
{
    NSInteger currentLength = [self length];
    NSString *result = @"";
    NSString *temp = @"";

    if (currentLength <= lengthlimit) { //If the string is already within limits
        return self;
    } else if (lengthlimit > 0) { //If the string is longer than the limit, and the limit is larger than 0.

        NSInteger newLimitWithoutEllipsis = lengthlimit - [Ellipsis length];

        if (preserveWords) {

            NSArray *wordsSeperated = [self tokenize];

            if ([wordsSeperated count] == 1) { // If this is a long word then we disregard preserveWords property.
                return [NSString stringWithFormat:@"%@%@", [self substringToIndex:newLimitWithoutEllipsis], Ellipsis];
            }

            for (NSString *word in wordsSeperated) {

                if ([temp isEqualToString:@""]) {
                    temp = word;
                } else {
                    temp = [NSString stringWithFormat:@"%@%@", temp, word];
                }

                if ([temp length] <= newLimitWithoutEllipsis) {
                    result = [temp copy];
                } else {
                    return [NSString stringWithFormat:@"%@%@",result,Ellipsis];
                }
            }
        } else {
            return [NSString stringWithFormat:@"%@%@", [self substringToIndex:newLimitWithoutEllipsis], Ellipsis];
        }

    } else { //if the limit is 0.
        return @"";
    }

    return self;
}

- (NSArray *)tokenize
{
    CFLocaleRef locale = CFLocaleCopyCurrent();
    CFRange stringRange = CFRangeMake(0, [self length]);

    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault,
                                                             (CFStringRef)self,
                                                             stringRange,
                                                             kCFStringTokenizerUnitWordBoundary,
                                                             locale);

    CFStringTokenizerTokenType tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer);

    NSMutableArray *tokens = [NSMutableArray new];

    while (tokenType != kCFStringTokenizerTokenNone) {
        stringRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);
        NSString *token = [self substringWithRange:NSMakeRange(stringRange.location, stringRange.length)];
        [tokens addObject:token];
        tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer);
    }

    CFRelease(locale);
    CFRelease(tokenizer);

    return tokens;
}

- (bool)wpkit_isEmpty {
    return self.length == 0;
}

@end

@implementation NSString (WPKitNumericValueHack)

- (NSNumber *)wpkit_numericValue {
    return [NSNumber numberWithUnsignedLongLong:[self longLongValue]];
}

@end

@implementation NSObject (WPKitNumericValueHack)
- (NSNumber *)wpkit_numericValue {
    if ([self isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)self;
    }
    return nil;
}
@end
