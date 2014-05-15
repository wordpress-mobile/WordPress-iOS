#import "StatsViewsVisitors.h"

NSString *const StatsViewsCategory = @"Views";
NSString *const StatsVisitorsCategory = @"Visitors";
NSString *const StatsPointNameKey = @"name";
NSString *const StatsPointCountKey = @"count";

@interface StatsViewsVisitors ()

@property (nonatomic, strong) NSMutableDictionary *viewsVisitorsData;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation StatsViewsVisitors

- (id)init {
    self = [super init];
    if (self) {
        _viewsVisitorsData = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSDateFormatter *)dateFormatter {
    if (_dateFormatter) {
        return _dateFormatter;
    }
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.locale = [NSLocale currentLocale];
    return _dateFormatter;
}

- (void)addViewsVisitorsWithData:(NSDictionary *)data unit:(StatsViewsVisitorsUnit)unit {
    NSMutableArray *periodToViews = [NSMutableArray array];
    NSMutableArray *periodToVisitors = [NSMutableArray array];
    NSArray *periodData = data[@"data"];
    [periodData enumerateObjectsUsingBlock:^(NSArray *d, NSUInteger idx, BOOL *stop) {
        [periodToViews addObject:@{StatsPointNameKey: [self nicePointName:d[0] forUnit:unit], StatsPointCountKey: d[1]}];
        [periodToVisitors addObject:@{StatsPointNameKey: [self nicePointName:d[0] forUnit:unit], StatsPointCountKey: d[2]}];
    }];
    
    self.dateFormatter = nil;
    
    _viewsVisitorsData[@(unit)] = @{StatsViewsCategory: periodToViews,
                                    StatsVisitorsCategory: periodToVisitors};
}

- (NSDictionary *)viewsVisitorsForUnit:(StatsViewsVisitorsUnit)unit {
    return _viewsVisitorsData[@(unit)];
}

- (NSString *)nicePointName:(NSString *)name forUnit:(StatsViewsVisitorsUnit)unit {
    if (name.length == 0) {
        DDLogWarn(@"Invalid date/name passed into nicePointName for unit: %i", unit);
        return @"";
    }
    
    switch (unit) {
        case StatsViewsVisitorsUnitDay:
        {
            self.dateFormatter.dateFormat = @"yyyy-MM-dd";
            NSDate *d = [self.dateFormatter dateFromString:name];
            self.dateFormatter.dateFormat = @"LLL dd";
            return [self.dateFormatter stringFromDate:d];
        }
        case StatsViewsVisitorsUnitWeek:
        {
            // Assumes format: yyyyWxxWxx first xx is month, second xx is first day of that week
            self.dateFormatter.dateFormat = @"yyyy'W'MM'W'dd";
            NSDate *d = [self.dateFormatter dateFromString:name];
            self.dateFormatter.dateFormat = @"LLL dd";
            return [self.dateFormatter stringFromDate:d];
        }
        case StatsViewsVisitorsUnitMonth:
        {
            self.dateFormatter.dateFormat = @"yyyy-MM-dd";
            NSDate *d = [self.dateFormatter dateFromString:name];
            self.dateFormatter.dateFormat = @"LLL yyyy"; // L is stand-alone month
            return [self.dateFormatter stringFromDate:d];
        }
        default:
            return @"";
    }
}

@end
