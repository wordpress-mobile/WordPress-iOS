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

    NSDictionary *map = isFutureDate ? [self futureConciseStringMap] : [self conciseStringMap];
    NSString *response = [map objectForKey:@(index)];
    if (response) {
        return response;
    }

    // Safety Net
    return responseForNoMatchFound;
}

+ (NSDictionary *)futureConciseStringMap
{
    return @{
             @1004 : NSLocalizedString(@"In many years", @"In many years"),
             @1003 : NSLocalizedString(@"In 3 years", @"In 3 years"),
             @1002 : NSLocalizedString(@"In 2 years", @"In 2 years"),
             @1001 : NSLocalizedString(@"Next year", @"Next year"),
             @112 : NSLocalizedString(@"In 12 months", @"In 12 months"),
             @111 : NSLocalizedString(@"In 11 months", @"In 11 months"),
             @110 : NSLocalizedString(@"In 10 months", @"In 10 months"),
             @109 : NSLocalizedString(@"In 9 months", @"In 9 months"),
             @108 : NSLocalizedString(@"In 8 months", @"In 8 months"),
             @107 : NSLocalizedString(@"In 7 months", @"In 7 months"),
             @106 : NSLocalizedString(@"In 6 months", @"In 6 months"),
             @105 : NSLocalizedString(@"In 5 months", @"In 5 months"),
             @104 : NSLocalizedString(@"In 4 months", @"In 4 months"),
             @103 : NSLocalizedString(@"In 3 months", @"In 3 months"),
             @102 : NSLocalizedString(@"In 2 months", @"In 2 months"),
             @101 : NSLocalizedString(@"Next month", @"Next month"),
             @31 : NSLocalizedString(@"In 31 days", @"In 31 days"),
             @30 : NSLocalizedString(@"In 30 days", @"In 30 days"),
             @29 : NSLocalizedString(@"In 29 days", @"In 29 days"),
             @28 : NSLocalizedString(@"In 28 days", @"In 28 days"),
             @27 : NSLocalizedString(@"In 27 days", @"In 27 days"),
             @26 : NSLocalizedString(@"In 26 days", @"In 26 days"),
             @25 : NSLocalizedString(@"In 25 days", @"In 25 days"),
             @24 : NSLocalizedString(@"In 24 days", @"In 24 days"),
             @23 : NSLocalizedString(@"In 23 days", @"In 23 days"),
             @22 : NSLocalizedString(@"In 22 days", @"In 22 days"),
             @21 : NSLocalizedString(@"In 21 days", @"In 21 days"),
             @20 : NSLocalizedString(@"In 20 days", @"In 20 days"),
             @19 : NSLocalizedString(@"In 19 days", @"In 19 days"),
             @18 : NSLocalizedString(@"In 18 days", @"In 18 days"),
             @17 : NSLocalizedString(@"In 17 days", @"In 17 days"),
             @16 : NSLocalizedString(@"In 16 days", @"In 16 days"),
             @15 : NSLocalizedString(@"In 15 days", @"In 15 days"),
             @14 : NSLocalizedString(@"In 14 days", @"In 14 days"),
             @13 : NSLocalizedString(@"In 13 days", @"In 13 days"),
             @12 : NSLocalizedString(@"In 12 days", @"In 12 days"),
             @11 : NSLocalizedString(@"In 11 days", @"In 11 days"),
             @10 : NSLocalizedString(@"In 10 days", @"In 10 days"),
             @9 : NSLocalizedString(@"In 9 days", @"In 9 days"),
             @8 : NSLocalizedString(@"In 8 days", @"In 8 days"),
             @7 : NSLocalizedString(@"In 7 days", @"In 7 days"),
             @6 : NSLocalizedString(@"In 6 days", @"In 6 days"),
             @5 : NSLocalizedString(@"In 5 days", @"In 5 days"),
             @4 : NSLocalizedString(@"In 4 days", @"In 4 days"),
             @3 : NSLocalizedString(@"In 3 days", @"In 3 days"),
             @2 : NSLocalizedString(@"In 2 days", @"In 2 days"),
             @1 : NSLocalizedString(@"Tomorrow", @"Tomorrow"),
             @0 : NSLocalizedString(@"Later Today", @"Later Today"),
             };
}

+ (NSDictionary *)conciseStringMap
{
    return @{
             @1004 : NSLocalizedString(@"4 years ago", @"4 years ago"),
             @1003 : NSLocalizedString(@"3 years ago", @"3 years ago"),
             @1002 : NSLocalizedString(@"2 years ago", @"2 years ago"),
             @1001 : NSLocalizedString(@"Last year", @"Last year"),
             @112 : NSLocalizedString(@"12 months ago", @"12 months ago"),
             @111 : NSLocalizedString(@"11 months ago", @"11 months ago"),
             @110 : NSLocalizedString(@"10 months ago", @"10 months ago"),
             @109 : NSLocalizedString(@"9 months ago", @"9 months ago"),
             @108 : NSLocalizedString(@"8 months ago", @"8 months ago"),
             @107 : NSLocalizedString(@"7 months ago", @"7 months ago"),
             @106 : NSLocalizedString(@"6 months ago", @"6 months ago"),
             @105 : NSLocalizedString(@"5 months ago", @"5 months ago"),
             @104 : NSLocalizedString(@"4 months ago", @"4 months ago"),
             @103 : NSLocalizedString(@"3 months ago", @"3 months ago"),
             @102 : NSLocalizedString(@"2 months ago", @"2 months ago"),
             @102 : NSLocalizedString(@"Last month", @"Last month"),
             @31 : NSLocalizedString(@"31 days ago", @"31 days ago"),
             @30 : NSLocalizedString(@"30 days ago", @"30 days ago"),
             @29 : NSLocalizedString(@"29 days ago", @"29 days ago"),
             @28 : NSLocalizedString(@"28 days ago", @"28 days ago"),
             @27 : NSLocalizedString(@"27 days ago", @"27 days ago"),
             @26 : NSLocalizedString(@"26 days ago", @"26 days ago"),
             @25 : NSLocalizedString(@"25 days ago", @"25 days ago"),
             @24 : NSLocalizedString(@"24 days ago", @"24 days ago"),
             @23 : NSLocalizedString(@"23 days ago", @"23 days ago"),
             @22 : NSLocalizedString(@"22 days ago", @"22 days ago"),
             @21 : NSLocalizedString(@"21 days ago", @"21 days ago"),
             @20 : NSLocalizedString(@"20 days ago", @"20 days ago"),
             @19 : NSLocalizedString(@"19 days ago", @"19 days ago"),
             @18 : NSLocalizedString(@"18 days ago", @"18 days ago"),
             @17 : NSLocalizedString(@"17 days ago", @"17 days ago"),
             @16 : NSLocalizedString(@"16 days ago", @"16 days ago"),
             @15 : NSLocalizedString(@"15 days ago", @"15 days ago"),
             @14 : NSLocalizedString(@"14 days ago", @"14 days ago"),
             @13 : NSLocalizedString(@"13 days ago", @"13 days ago"),
             @12 : NSLocalizedString(@"12 days ago", @"12 days ago"),
             @11 : NSLocalizedString(@"11 days ago", @"11 days ago"),
             @10 : NSLocalizedString(@"10 days ago", @"10 days ago"),
             @9 : NSLocalizedString(@"9 days ago", @"9 days ago"),
             @8 : NSLocalizedString(@"8 days ago", @"8 days ago"),
             @7 : NSLocalizedString(@"7 days ago", @"7 days ago"),
             @6 : NSLocalizedString(@"6 days ago", @"6 days ago"),
             @5 : NSLocalizedString(@"5 days ago", @"5 days ago"),
             @4 : NSLocalizedString(@"4 days ago", @"4 days ago"),
             @3 : NSLocalizedString(@"3 days ago", @"3 days ago"),
             @2 : NSLocalizedString(@"2 days ago", @"2 days ago"),
             @1 : NSLocalizedString(@"Yesterday", @"Yesterday"),
             @0 : NSLocalizedString(@"Today", @"Today"),
             };
}

@end
