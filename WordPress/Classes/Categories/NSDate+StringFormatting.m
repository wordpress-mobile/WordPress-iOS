#import "NSDate+StringFormatting.h"

@implementation NSDate (StringFormatting)

- (NSString *)shortString
{
    NSString *shortString;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
                                                   fromDate:self
                                                     toDate:[NSDate date]
                                                    options:0];

    NSInteger day = ABS(dateComponents.day);
    NSInteger hour = ABS(dateComponents.hour);
    NSInteger minute = ABS(dateComponents.minute);
    NSInteger second = ABS(dateComponents.second);

    if (day > 0) {
        if (dateComponents.day < 0) {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"In %id", @"In _ days, Days duration single character abbreviation"), day];
        } else {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"%id", @"Days duration single character abbreviation"), day];
        }
    } else if (hour > 0) {
        if (dateComponents.hour < 0) {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"In %ih", @"In _ hours, Hours duration single character abbreviation"), hour];
        } else {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"%ih", @"Hours duration single character abbreviation"), hour];
        }
    } else if (minute > 0) {
        if (dateComponents.minute < 0) {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"In %im", @"In _ minutes, Minutes duration single character abbreviation"), minute];
        } else {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"%im", @"Minutes duration single character abbreviation"), minute];
        }
    } else {
        if (dateComponents.second < 0) {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"In %is", @"In _ seconds, Seconds duration single character abbreviation"), second];
        } else {
            shortString = [NSString stringWithFormat:NSLocalizedString(@"%is", @"Seconds duration single character abbreviation"), second];
        }
    }

    return shortString;
}

@end
