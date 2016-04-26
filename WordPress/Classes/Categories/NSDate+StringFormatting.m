#import "NSDate+StringFormatting.h"
#import "WordPress-Swift.h"
#import <FormatterKit/TTTTimeIntervalFormatter.h>

@implementation NSDate (StringFormatting)

- (NSString *)shortString
{
    NSString *shortString;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                   fromDate:self
                                                     toDate:[NSDate date]
                                                    options:0];

    TTTTimeIntervalFormatter *dateFormater = [[TTTTimeIntervalFormatter alloc] init];
    shortString =  [dateFormater stringForTimeInterval:[self timeIntervalSinceNow]];

    return shortString;
}

@end
