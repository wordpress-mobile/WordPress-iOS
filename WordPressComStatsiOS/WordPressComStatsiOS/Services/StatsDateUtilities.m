#import "StatsDateUtilities.h"

@interface StatsDateUtilities ()

@property (nonatomic, strong) NSTimeZone *timeZone;

@end

@implementation StatsDateUtilities

- (instancetype)init
{
    self = [self initWithTimeZone:[NSTimeZone localTimeZone]];
    if (self) {
        
    }
    
    return self;
}


- (instancetype)initWithTimeZone:(NSTimeZone *)timeZone
{
    self = [super init];
    if (self) {
        _timeZone = timeZone;
    }
    
    return self;
}


- (NSDate *)calculateEndDateForPeriodUnit:(StatsPeriodUnit)unit withDateWithinPeriod:(NSDate *)date
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = self.timeZone;
    
    if (unit == StatsPeriodUnitDay) {
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
        dateComponents.hour = 23;
        dateComponents.minute = 59;
        dateComponents.second = 59;
        date = [calendar dateFromComponents:dateComponents];
        
        return date;
    } else if (unit == StatsPeriodUnitMonth) {
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:date];
        dateComponents.hour = 23;
        dateComponents.minute = 59;
        dateComponents.second = 59;
        date = [calendar dateFromComponents:dateComponents];
        
        dateComponents = [NSDateComponents new];
        dateComponents.day = -1;
        dateComponents.month = +1;
        date = [calendar dateByAddingComponents:dateComponents toDate:date options:0];
        
        return date;
    } else if (unit == StatsPeriodUnitWeek) {
        // Weeks are Monday - Sunday
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYearForWeekOfYear | NSCalendarUnitWeekday | NSCalendarUnitWeekOfYear fromDate:date];
        NSInteger weekDay = dateComponents.weekday;
        
        if (weekDay > 1) {
            dateComponents = [NSDateComponents new];
            dateComponents.weekday = 8 - weekDay;
            date = [calendar dateByAddingComponents:dateComponents toDate:date options:0];
        }
        
        // Force time
        dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
        dateComponents.hour = 23;
        dateComponents.minute = 59;
        dateComponents.second = 59;
        date = [calendar dateFromComponents:dateComponents];
        
        return date;
    } else if (unit == StatsPeriodUnitYear) {
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear fromDate:date];
        dateComponents.hour = 23;
        dateComponents.minute = 59;
        dateComponents.second = 59;
        date = [calendar dateFromComponents:dateComponents];
        
        dateComponents = [NSDateComponents new];
        dateComponents.day = -1;
        dateComponents.year = +1;
        date = [calendar dateByAddingComponents:dateComponents toDate:date options:0];
        
        return date;
    }
    
    return nil;
}


- (NSString *)dateAgeForDate:(NSDate *)date
{
    if (!date) {
        return @"";
    }
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = self.timeZone;
    NSDate *now = [NSDate date];
    
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay
                                                   fromDate:date
                                                     toDate:now
                                                    options:0];
    NSDateComponents *niceDateComponents = [calendar components:NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                       fromDate:date
                                                         toDate:now
                                                        options:0];
    
    if (dateComponents.day >= 548) {
        return [NSString stringWithFormat:NSLocalizedString(@"%d years", @"Age between dates over one year."), niceDateComponents.year];
    } else if (dateComponents.day >= 345) {
        return NSLocalizedString(@"a year", @"Age between dates equaling one year.");
    } else if (dateComponents.day >= 45) {
        return [NSString stringWithFormat:NSLocalizedString(@"%d months", @"Age between dates over one month."), niceDateComponents.month];
    } else if (dateComponents.day >= 25) {
        return NSLocalizedString(@"a month", @"Age between dates equaling one month.");
    } else if (dateComponents.day > 1 || (dateComponents.day == 1 && dateComponents.hour >= 12)) {
        return [NSString stringWithFormat:NSLocalizedString(@"%d days", @"Age between dates over one day."), niceDateComponents.day];
    } else if (dateComponents.hour >= 22) {
        return NSLocalizedString(@"a day", @"Age between dates equaling one day.");
    } else if (dateComponents.hour > 1 || (dateComponents.hour == 1 && dateComponents.minute >= 30)) {
        return [NSString stringWithFormat:NSLocalizedString(@"%d hours", @"Age between dates over one hour."), niceDateComponents.hour];
    } else if (dateComponents.minute >= 45) {
        return NSLocalizedString(@"an hour", @"Age between dates equaling one hour.");
    } else {
        return NSLocalizedString(@"<1 hour", @"Age between dates less than one hour.");
    }
}




@end
