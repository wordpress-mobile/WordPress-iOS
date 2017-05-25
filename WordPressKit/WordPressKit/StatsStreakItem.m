#import "StatsStreakItem.h"

@implementation StatsStreakItem

- (id)copyWithZone:(NSZone *)zone
{
    StatsStreakItem *copy = [[StatsStreakItem alloc] init];
    
    if (copy) {
        copy.value = self.value;
        copy.timeStamp = self.timeStamp;
    }
    
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"StatsStreakItem - timestamp: %@, date: %@, value: %@", self.timeStamp, self.date, self.value];
}

- (NSDate *)date
{
    NSDate *convertedDate;
    if (self.timeStamp) {
        NSTimeInterval interval = [self.timeStamp doubleValue];
        convertedDate = [NSDate dateWithTimeIntervalSince1970:interval];
    }
    
    return convertedDate;
}

@end
