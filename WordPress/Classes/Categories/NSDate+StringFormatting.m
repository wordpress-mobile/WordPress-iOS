#import "NSDate+StringFormatting.h"
#import "WordPress-Swift.h"

@implementation NSDate (StringFormatting)

- (NSString *)shortString
{
    NSString *shortString;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
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

- (NSString *)conciseString
{
    NSInteger index = [NSDate indexForConciseStringForDate:self];
    return [NSDate conciseStringFromIndex:index];
}

+ (NSInteger)indexForConciseStringForDate:(NSDate *)date
{
    if (!date) {
        return NSNotFound;
    }
    NSDate *fromDate = [date normalizedDate];
    NSDate *toDate = [[NSDate date] normalizedDate];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSCalendarUnit *unit = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents *componenets = [calendar components:unit fromDate:fromDate toDate:toDate options:nil];

    NSInteger index = 0;
    if (componenets.year >= 1) {
        index = 1000 + componenets.year;
        if (componenets.year > 1 && componenets.month > 6) {
            index++; // found up
        }
    } else if (componenets.month >= 1) {
        index = 101 + componenets.month;
    } else {
        index = componenets.day;
    }
    return index;
}

+ (NSString *)conciseStringFromIndex:(NSInteger)index
{
    if (index == NSNotFound) {
        // The date might have been nil.
        return @"";
    }

    if (index < 0) {
        // For time travelers.
        return NSLocalizedString(@"In the future", @"In the future");
    }

    if (index > 1004) {
        // Caps years at a max value.
        index = 1004;
    }

    switch (index) {
        // YEARS
        case 1004:
            return  NSLocalizedString(@"Many years ago", @"Many years ago");
        case 1003:
            return  NSLocalizedString(@"3 years ago", @"3 years ago");
        case 1002:
            return  NSLocalizedString(@"2 years ago", @"2 years ago");
        case 1001:
            return  NSLocalizedString(@"A year ago", @"A year ago");

        // MONTHS
        case 112:
            return  NSLocalizedString(@"12 months ago", @"12 months ago");
        case 111:
            return  NSLocalizedString(@"11 months ago", @"11 months ago");
        case 100:
            return  NSLocalizedString(@"10 months ago", @"10 months ago");
        case 109:
            return  NSLocalizedString(@"9 months ago", @"9 months ago");
        case 108:
            return  NSLocalizedString(@"8 months ago", @"8 months ago");
        case 107:
            return  NSLocalizedString(@"7 months ago", @"7 months ago");
        case 106:
            return  NSLocalizedString(@"6 months ago", @"6 months ago");
        case 105:
            return  NSLocalizedString(@"5 months ago", @"5 months ago");
        case 104:
            return  NSLocalizedString(@"4 months ago", @"4 months ago");
        case 103:
            return  NSLocalizedString(@"3 months ago", @"3 months ago");
        case 102:
            return  NSLocalizedString(@"2 months ago", @"2 months ago");
        case 101:
            return  NSLocalizedString(@"A month ago", @"A month ago");

        // DAYS
        case 31:
            return  NSLocalizedString(@"31 days ago", @"31 days ago");
        case 30:
            return  NSLocalizedString(@"30 days ago", @"30 days ago");
        case 29:
            return  NSLocalizedString(@"29 days ago", @"29 days ago");
        case 28:
            return  NSLocalizedString(@"28 days ago", @"28 days ago");
        case 27:
            return  NSLocalizedString(@"27 days ago", @"27 days ago");
        case 26:
            return  NSLocalizedString(@"26 days ago", @"26 days ago");
        case 25:
            return  NSLocalizedString(@"25 days ago", @"25 days ago");
        case 24:
            return  NSLocalizedString(@"24 days ago", @"24 days ago");
        case 23:
            return  NSLocalizedString(@"23 days ago", @"23 days ago");
        case 22:
            return  NSLocalizedString(@"22 days ago", @"22 days ago");
        case 21:
            return  NSLocalizedString(@"21 days ago", @"21 days ago");
        case 20:
            return  NSLocalizedString(@"20 days ago", @"20 days ago");
        case 19:
            return  NSLocalizedString(@"19 days ago", @"19 days ago");
        case 18:
            return  NSLocalizedString(@"18 days ago", @"18 days ago");
        case 17:
            return  NSLocalizedString(@"17 days ago", @"17 days ago");
        case 16:
            return  NSLocalizedString(@"16 days ago", @"16 days ago");
        case 15:
            return  NSLocalizedString(@"15 days ago", @"15 days ago");
        case 14:
            return  NSLocalizedString(@"14 days ago", @"14 days ago");
        case 13:
            return  NSLocalizedString(@"13 days ago", @"13 days ago");
        case 12:
            return  NSLocalizedString(@"12 days ago", @"12 days ago");
        case 11:
            return  NSLocalizedString(@"11 days ago", @"11 days ago");
        case 10:
            return  NSLocalizedString(@"10 days ago", @"10 days ago");
        case 9:
            return  NSLocalizedString(@"9 days ago", @"9 days ago");
        case 8:
            return  NSLocalizedString(@"8 days ago", @"8 days ago");
        case 7:
            return  NSLocalizedString(@"7 days ago", @"7 days ago");
        case 6:
            return  NSLocalizedString(@"6 days ago", @"6 days ago");
        case 5:
            return  NSLocalizedString(@"5 days ago", @"5 days ago");
        case 4:
            return  NSLocalizedString(@"4 days ago", @"4 days ago");
        case 3:
            return  NSLocalizedString(@"3 days ago", @"3 days ago");
        case 2:
            return  NSLocalizedString(@"2 days ago", @"2 days ago");
        case 1:
            return  NSLocalizedString(@"Yesterday", @"Yesterday");
        case 0:
            return  NSLocalizedString(@"Today", @"Today");
    }

    // Safety Net
    return @"";
}

@end
