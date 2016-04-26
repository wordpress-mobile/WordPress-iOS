#import "NSDate+StringFormatting.h"
#import "WordPress-Swift.h"
#import <FormatterKit/TTTTimeIntervalFormatter.h>

@implementation NSDate (StringFormatting)

+ (NSDateFormatter *)shortDateFormatter
{
    static NSDateFormatter *_shortDateFormatter = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _shortDateFormatter = [[NSDateFormatter alloc] init];
        _shortDateFormatter.dateStyle = NSDateFormatterMediumStyle;
        _shortDateFormatter.timeStyle = NSDateFormatterNoStyle;
    });

    return _shortDateFormatter;
}

- (NSString *)shortString
{
    NSString *shortString;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                   fromDate:self
                                                     toDate:[NSDate date]
                                                    options:0];
    NSInteger day = ABS(dateComponents.day);
    if (day < 7) {
        TTTTimeIntervalFormatter *dateFormater = [[TTTTimeIntervalFormatter alloc] init];
        shortString =  [dateFormater stringForTimeInterval:[self timeIntervalSinceNow]];
    } else {
        shortString = [[[self class] shortDateFormatter] stringFromDate:self];
    }

    return shortString;
}

@end
