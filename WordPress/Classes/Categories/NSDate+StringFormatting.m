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
    NSDate *now = [[NSDate date] normalizedDate];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSCalendarUnit *unit = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents *dateComponents = [calendar components:unit fromDate:fromDate toDate:now options:nil];

    NSInteger index = 0;
    BOOL isFutureDate = ([fromDate timeIntervalSinceNow] > 0);
    NSInteger year = ABS(dateComponents.year);
    NSInteger month = ABS(dateComponents.month);
    NSInteger day = ABS(dateComponents.day);

    if (year >= 1) {
        index = 1000 + year;
        if (year > 1 && month > 6) {
            index++; // round up
        }
    } else if (month >= 1) {
        index = 101 + month;
    } else {
        index = day;
    }

    if (isFutureDate) {
        index *= -1;
    }
    return index;
}

+ (NSString *)conciseStringFromIndex:(NSInteger)index
{
    NSInteger maxYears = 1004;
    NSString *responseForNoMatchFound = [NSString string];
    if (index == NSNotFound) {
        // The date might have been nil.
        return responseForNoMatchFound;
    }

    BOOL isFutureDate = index < 0;
    // Normalize
    index = ABS(index);

    if (index > maxYears) {
        // Caps years at a max value.
        index = maxYears;
    }

    switch (index) {
        // YEARS
        case 1004:
            if (isFutureDate) {
                return  NSLocalizedString(@"In many years", @"In many years");
            } else {
                return  NSLocalizedString(@"Many years ago", @"Many years ago");
            }
        case 1003:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 3 years", @"In 3 years");
            } else {
                return  NSLocalizedString(@"3 years ago", @"3 years ago");
            }
        case 1002:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 2 years", @"In 2 years");
            } else {
                return  NSLocalizedString(@"2 years ago", @"2 years ago");
            }
        case 1001:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 1 year", @"In 1 year");
            } else {
                return  NSLocalizedString(@"A year ago", @"A year ago");
            }

        // MONTHS
        case 112:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 12 months", @"In 12 months");
            } else {
                return  NSLocalizedString(@"12 months ago", @"12 months ago");
            }
        case 111:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 11 months", @"In 11 months");
            } else {
                return  NSLocalizedString(@"11 months ago", @"11 months ago");
            }
        case 110:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 10 months", @"In 10 months");
            } else {
                return  NSLocalizedString(@"10 months ago", @"10 months ago");
            }
        case 109:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 9 months", @"In 9 months");
            } else {
                return  NSLocalizedString(@"9 months ago", @"9 months ago");
            }
        case 108:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 8 months", @"In 8 months");
            } else {
                return  NSLocalizedString(@"8 months ago", @"8 months ago");
            }
        case 107:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 7 months", @"In 7 months");
            } else {
                return  NSLocalizedString(@"7 months ago", @"7 months ago");
            }
        case 106:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 6 months", @"In 6 months");
            } else {
                return  NSLocalizedString(@"6 months ago", @"6 months ago");
            }
        case 105:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 5 months", @"In 5 months");
            } else {
                return  NSLocalizedString(@"5 months ago", @"5 months ago");
            }
        case 104:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 4 months", @"In 4 months");
            } else {
                return  NSLocalizedString(@"4 months ago", @"4 months ago");
            }
        case 103:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 3 months", @"In 3 months");
            } else {
                return  NSLocalizedString(@"3 months ago", @"3 months ago");
            }
        case 102:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 2 months", @"In 2 months");
            } else {
                return  NSLocalizedString(@"2 months ago", @"2 months ago");
            }
        case 101:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 1 month", @"In 1 month");
            } else {
                return  NSLocalizedString(@"A month ago", @"A months ago");
            }

        // DAYS
        case 31:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 31 days", @"In 31 days");
            } else {
                return  NSLocalizedString(@"31 days ago", @"31 days ago");
            }
        case 30:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 30 days", @"In 30 days");
            } else {
                return  NSLocalizedString(@"30 days ago", @"30 days ago");
            }
        case 29:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 29 days", @"In 29 days");
            } else {
                return  NSLocalizedString(@"29 days ago", @"29 days ago");
            }
        case 28:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 28 days", @"In 28 days");
            } else {
                return  NSLocalizedString(@"28 days ago", @"28 days ago");
            }
        case 27:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 27 days", @"In 27 days");
            } else {
                return  NSLocalizedString(@"27 days ago", @"27 days ago");
            }
        case 26:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 26 days", @"In 26 days");
            } else {
                return  NSLocalizedString(@"26 days ago", @"26 days ago");
            }
        case 25:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 25 days", @"In 25 days");
            } else {
                return  NSLocalizedString(@"25 days ago", @"25 days ago");
            }
        case 24:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 24 days", @"In 24 days");
            } else {
                return  NSLocalizedString(@"24 days ago", @"24 days ago");
            }
        case 23:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 23 days", @"In 23 days");
            } else {
                return  NSLocalizedString(@"23 days ago", @"23 days ago");
            }
        case 22:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 22 days", @"In 22 days");
            } else {
                return  NSLocalizedString(@"22 days ago", @"22 days ago");
            }
        case 21:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 21 days", @"In 21 days");
            } else {
                return  NSLocalizedString(@"21 days ago", @"21 days ago");
            }
        case 20:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 20 days", @"In 20 days");
            } else {
                return  NSLocalizedString(@"20 days ago", @"20 days ago");
            }
        case 19:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 19 days", @"In 19 days");
            } else {
                return  NSLocalizedString(@"19 days ago", @"19 days ago");
            }
        case 18:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 18 days", @"In 18 days");
            } else {
                return  NSLocalizedString(@"18 days ago", @"18 days ago");
            }
        case 17:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 17 days", @"In 17 days");
            } else {
                return  NSLocalizedString(@"17 days ago", @"17 days ago");
            }
        case 16:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 16 days", @"In 16 days");
            } else {
                return  NSLocalizedString(@"16 days ago", @"16 days ago");
            }
        case 15:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 15 days", @"In 15 days");
            } else {
                return  NSLocalizedString(@"15 days ago", @"15 days ago");
            }
        case 14:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 14 days", @"In 14 days");
            } else {
                return  NSLocalizedString(@"14 days ago", @"14 days ago");
            }
        case 13:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 13 days", @"In 13 days");
            } else {
                return  NSLocalizedString(@"13 days ago", @"13 days ago");
            }
        case 12:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 12 days", @"In 12 days");
            } else {
                return  NSLocalizedString(@"12 days ago", @"12 days ago");
            }
        case 11:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 11 days", @"In 11 days");
            } else {
                return  NSLocalizedString(@"11 days ago", @"11 days ago");
            }
        case 10:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 10 days", @"In 10 days");
            } else {
                return  NSLocalizedString(@"10 days ago", @"10 days ago");
            }
        case 9:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 9 days", @"In 9 days");
            } else {
                return  NSLocalizedString(@"9 days ago", @"9 days ago");
            }
        case 8:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 8 days", @"In 8 days");
            } else {
                return  NSLocalizedString(@"8 days ago", @"8 days ago");
            }
        case 7:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 7 days", @"In 7 days");
            } else {
                return  NSLocalizedString(@"7 days ago", @"7 days ago");
            }
        case 6:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 6 days", @"In 6 days");
            } else {
                return  NSLocalizedString(@"6 days ago", @"6 days ago");
            }
        case 5:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 5 days", @"In 5 days");
            } else {
                return  NSLocalizedString(@"5 days ago", @"5 days ago");
            }
        case 4:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 4 days", @"In 4 days");
            } else {
                return  NSLocalizedString(@"4 days ago", @"4 days ago");
            }
        case 3:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 3 days", @"In 3 days");
            } else {
                return  NSLocalizedString(@"3 days ago", @"3 days ago");
            }
        case 2:
            if (isFutureDate) {
                return  NSLocalizedString(@"In 2 days", @"In 2 days");
            } else {
                return  NSLocalizedString(@"2 days ago", @"2 days ago");
            }
        case 1:
            if (isFutureDate) {
                return  NSLocalizedString(@"Tomorrow", @"Tomorrow");
            } else {
                return  NSLocalizedString(@"Yesterday", @"Yesterday");
            }
        case 0:
            if (isFutureDate) {
                return  NSLocalizedString(@"Later today", @"Later today");
            } else {
                return  NSLocalizedString(@"Today", @"Today");
            }
    }

    // Safety Net
    return responseForNoMatchFound;
}

@end
