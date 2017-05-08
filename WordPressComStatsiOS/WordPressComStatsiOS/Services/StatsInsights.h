#import <Foundation/Foundation.h>

@interface StatsInsights : NSObject

@property (nonatomic, copy) NSString *highestHour;
@property (nonatomic, copy) NSString *highestHourPercent;
@property (nonatomic, strong) NSNumber *highestHourPercentValue;
@property (nonatomic, copy) NSString *highestDayOfWeek;
@property (nonatomic, copy) NSString *highestDayPercent;
@property (nonatomic, strong) NSNumber *highestDayPercentValue;

@end
