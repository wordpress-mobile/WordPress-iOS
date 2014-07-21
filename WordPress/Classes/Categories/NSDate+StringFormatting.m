#import "NSDate+StringFormatting.h"

@implementation NSDate (StringFormatting)

- (NSString *)shortString {
    NSString *shortString;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
                                                   fromDate:self
                                                     toDate:[NSDate date]
                                                    options:0];

    if (dateComponents.day > 0) {
        shortString = [NSString stringWithFormat:NSLocalizedString(@"%id", @"Days duration single character abbreviation"), dateComponents.day];
    } else if (dateComponents.hour > 0) {
        shortString = [NSString stringWithFormat:NSLocalizedString(@"%ih", @"Hours duration single character abbreviation"), dateComponents.hour];
    } else if (dateComponents.minute > 0) {
        shortString = [NSString stringWithFormat:NSLocalizedString(@"%im", @"Minutes duration single character abbreviation"), dateComponents.minute];
    } else {
        shortString = [NSString stringWithFormat:NSLocalizedString(@"%is", @"Seconds duration single character abbreviation"), dateComponents.second];
    }

    return shortString;
}

- (NSString *)longString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd, yyyy, hh:mm a"];
    return [dateFormatter stringFromDate:self];
}

@end
