//
//  NSString+XMLExtensions.m
//  WordPress
//
//  Created by Janakiram on 26/08/08.
//

#import "NSString+XMLExtensions.h"

@implementation NSString (XMLExtensions)

+ (NSString *)encodeXMLCharactersIn : (NSString *)source {
    if (![source isKindOfClass:[NSString class]] || !source)
        return @"";

    NSString *result = [NSString stringWithString:source];

    if ([result rangeOfString:@"&"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"&"] componentsJoinedByString:@"&amp;"];

    if ([result rangeOfString:@"<"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"<"] componentsJoinedByString:@"&lt;"];

    if ([result rangeOfString:@">"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@">"] componentsJoinedByString:@"&gt;"];

    if ([result rangeOfString:@"\""].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"\""] componentsJoinedByString:@"&quot;"];

    if ([result rangeOfString:@"'"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"'"] componentsJoinedByString:@"&apos;"];

    return result;
}

+ (NSString *)decodeXMLCharactersIn:(NSString *)source {
    if (![source isKindOfClass:[NSString class]] || !source)
        return @"";

    NSString *result = [NSString stringWithString:source];

    if ([result rangeOfString:@"&amp;"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"&amp;"] componentsJoinedByString:@"&"];

    if ([result rangeOfString:@"&lt;"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"&lt;"] componentsJoinedByString:@"<"];

    if ([result rangeOfString:@"&gt;"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"&gt;"] componentsJoinedByString:@">"];

    if ([result rangeOfString:@"&quot;"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"&quot;"] componentsJoinedByString:@"\""];

    if ([result rangeOfString:@"&apos;"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"&apos;"] componentsJoinedByString:@"'"];

    if ([result rangeOfString:@"&nbsp;"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"&nbsp;"] componentsJoinedByString:@" "];

    if ([result rangeOfString:@"&#8220;"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"&#8220;"] componentsJoinedByString:@"\""];

    if ([result rangeOfString:@"&#8221;"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"&#8221;"] componentsJoinedByString:@"\""];

	if ([result rangeOfString:@"&#039;"].location != NSNotFound)
        result = [[result componentsSeparatedByString:@"&#039;"] componentsJoinedByString:@"'"];

    return result;
}

@end
