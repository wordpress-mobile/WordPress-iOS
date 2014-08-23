#import "NSScanner+Helpers.h"

@implementation NSScanner (Helpers)

- (NSString *)scanQuotedText
{
    NSString *scanned = nil;
    
    while ([self isAtEnd] == NO) {
        [self scanUpToString:@"\"" intoString:nil];
        [self scanString:@"\"" intoString:nil];
        [self scanUpToString:@"\"" intoString:&scanned];
        [self scanString:@"\"" intoString:nil];
    }
    
    return (scanned.length > 0) ? scanned : nil;
}

@end
