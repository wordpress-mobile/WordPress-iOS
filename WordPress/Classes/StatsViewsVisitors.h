/*
 * StatsViewsVisitors.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, StatsViewsVisitorsUnit) {
    StatsViewsVisitorsUnitDay,
    StatsViewsVisitorsUnitWeek,
    StatsViewsVisitorsUnitMonth
};

extern NSString *const StatsViewsCategory;
extern NSString *const StatsVisitorsCategory;
extern NSString *const StatsPointNameKey;
extern NSString *const StatsPointCountKey;

@interface StatsViewsVisitors : NSObject

- (void)addViewsVisitorsWithData:(NSDictionary *)data unit:(StatsViewsVisitorsUnit)unit;
- (NSDictionary *)viewsVisitorsForUnit:(StatsViewsVisitorsUnit)unit;

@end
