#import "NSDate+StringFormatting.h"
#import "WordPress-Swift.h"
#import <FormatterKit/TTTTimeIntervalFormatter.h>

@implementation NSDate (StringFormatting)

- (NSString *)shortString
{    
    TTTTimeIntervalFormatter *dateFormater = [[TTTTimeIntervalFormatter alloc] init];
    NSString *shortString =  [dateFormater stringForTimeInterval:[self timeIntervalSinceNow]];

    return shortString;
}

@end
