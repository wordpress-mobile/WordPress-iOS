#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WPStatsViewsVisitorsUnit) {
    StatsViewsVisitorsUnitDay,
    StatsViewsVisitorsUnitWeek,
    StatsViewsVisitorsUnitMonth
};

extern NSString *const StatsViewsCategory;
extern NSString *const StatsVisitorsCategory;
extern NSString *const StatsPointNameKey;
extern NSString *const StatsPointCountKey;

@interface WPStatsViewsVisitors : NSObject

- (void)addViewsVisitorsWithData:(NSDictionary *)data unit:(WPStatsViewsVisitorsUnit)unit;
- (NSDictionary *)viewsVisitorsForUnit:(WPStatsViewsVisitorsUnit)unit;

@end
