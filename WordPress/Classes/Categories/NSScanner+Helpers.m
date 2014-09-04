#import "NSScanner+Helpers.h"



@implementation NSScanner (Helpers)

- (NSArray *)scanQuotedText
{
    NSMutableArray *scanned = [NSMutableArray array];
    NSString *quote         = nil;
    
    while ([self isAtEnd] == NO) {
        [self scanUpToString:@"\""  intoString:nil];
        [self scanString:@"\""      intoString:nil];
        [self scanUpToString:@"\""  intoString:&quote];
        [self scanString:@"\""      intoString:nil];
        
        if (quote.length) {
            [scanned addObject:quote];
        }
    }

    return scanned;
}

@end
