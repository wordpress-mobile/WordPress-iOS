#import <Foundation/Foundation.h>
@import WordPressKit;

@interface StatsDateUtilities : NSObject

- (instancetype)initWithTimeZone:(NSTimeZone *)timeZone;

- (NSDate *)calculateEndDateForPeriodUnit:(StatsPeriodUnit)unit withDateWithinPeriod:(NSDate *)date;
- (NSString *)dateAgeForDate:(NSDate *)date;

@end
