#import "NSDate+StringFormatting.h"
#import "WordPress-Swift.h"

@implementation NSDate (StringFormatting)

- (NSString *)shortString
{
    NSString *shortString;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                   fromDate:self
                                                     toDate:[NSDate date]
                                                    options:0];

    BOOL isFutureDate = ([self timeIntervalSinceNow] > 0);
    NSInteger day = ABS(dateComponents.day);
    NSInteger hour = ABS(dateComponents.hour);
    NSInteger minute = ABS(dateComponents.minute);
    NSInteger second = ABS(dateComponents.second);

    if (day > 0) {
        if (isFutureDate) {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"In %id", @"In _ days, Days duration single character abbreviation"), day];
        } else {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"%id", @"Days duration single character abbreviation"), day];
        }
    } else if (hour > 0) {
        if (isFutureDate) {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"In %ih", @"In _ hours, Hours duration single character abbreviation"), hour];
        } else {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"%ih", @"Hours duration single character abbreviation"), hour];
        }
    } else if (minute > 0) {
        if (isFutureDate) {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"In %im", @"In _ minutes, Minutes duration single character abbreviation"), minute];
        } else {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"%im", @"Minutes duration single character abbreviation"), minute];
        }
    } else {
        if (isFutureDate) {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"In seconds", @"A short phrase indicating something due to happen in a few moments. An example is when a scheduled post will published in under a minute."), second];
        } else {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"Just now", @"A short phrase indicating something that happened moments ago. An example is when a post was published less than a minute ago."), second];
        }
    }

    return shortString;
}

@end
