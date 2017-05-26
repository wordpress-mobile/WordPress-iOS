#import "StatsStreak.h"

@implementation StatsStreak

- (id)copyWithZone:(NSZone *)zone
{
    StatsStreak *copy = [[StatsStreak alloc] init];
    
    if (copy) {
        copy.longestStreakLength = self.longestStreakLength;
        copy.longestStreakStartDate = self.longestStreakStartDate;
        copy.longestStreakEndDate = self.longestStreakEndDate;
        copy.currentStreakLength = self.currentStreakLength;
        copy.currentStreakStartDate = self.currentStreakStartDate;
        copy.currentStreakEndDate = self.currentStreakEndDate;
        copy.errorWhileRetrieving = self.errorWhileRetrieving;        
        copy.items = [[NSArray alloc] initWithArray:self.items copyItems:true];
    }
    
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"StatsStreak- longest length: %@, longest start date: %@, longest end date: %@ -- current length: %@, current start date: %@, current end date: %@",
            self.longestStreakLength,
            self.longestStreakStartDate,
            self.longestStreakEndDate,
            self.currentStreakLength,
            self.currentStreakStartDate,
            self.currentStreakEndDate];
}

- (void)pruneItemsOutsideOfMonth:(NSDate*)date
{
    if (date && self.items) {
        NSMutableArray *newItems = [NSMutableArray array];
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        for (StatsStreakItem *item in self.items) {
            NSInteger month = [gregorianCalendar component:NSCalendarUnitMonth fromDate:date];
            NSInteger itemMonth = [gregorianCalendar component:NSCalendarUnitMonth fromDate:item.date];
            NSInteger year = [gregorianCalendar component:NSCalendarUnitYear fromDate:date];
            NSInteger itemYear = [gregorianCalendar component:NSCalendarUnitYear fromDate:item.date];
            
            if ((year == itemYear) && (month == itemMonth)) {
                [newItems addObject:item];
            }
        }
        self.items = [newItems copy];
    }
}

@end
