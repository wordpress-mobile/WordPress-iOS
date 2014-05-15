#import "NSRegularExpression+Helpers.h"


@implementation NSRegularExpression (Helpers)

+ (NSRegularExpression *)sharedJavascriptRegex
{
    // Note:
    // Setting up a NSRegularExpression instance is a time consuming OP. Let's create just one instance, and share it accordingly
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        regex = [NSRegularExpression regularExpressionWithPattern:@"<script[^>]*>[\\w\\W]*</script>" options:NSRegularExpressionCaseInsensitive error:&error];
    });
    
    return regex;
}

@end
