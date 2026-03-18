#import "NSString+Helpers.h"
#import <CommonCrypto/CommonDigest.h>

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
