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
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"MMM dd, yyyy, hh:mm a"];
    });

    return [_dateFormatter stringFromDate:self];
}

@end
