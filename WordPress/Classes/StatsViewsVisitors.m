/*
 * StatsViewsVisitors.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsViewsVisitors.h"

NSString *const StatsViewsCategory = @"Views";
NSString *const StatsVisitorsCategory = @"Visitors";
NSString *const StatsPointNameKey = @"name";
NSString *const StatsPointCountKey = @"count";

@interface StatsViewsVisitors ()

@property (nonatomic, strong) NSMutableDictionary *viewsVisitorsData;

@end

@implementation StatsViewsVisitors

- (id)init {
    self = [super init];
    if (self) {
        _viewsVisitorsData = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addViewsVisitorsWithData:(NSDictionary *)data unit:(StatsViewsVisitorsUnit)unit {
    NSMutableArray *periodToViews = [NSMutableArray array];
    NSMutableArray *periodToVisitors = [NSMutableArray array];
    NSArray *periodData = data[@"data"];
    [periodData enumerateObjectsUsingBlock:^(NSArray *d, NSUInteger idx, BOOL *stop) {
        [periodToViews addObject:@{StatsPointNameKey: d[0], StatsPointCountKey: d[1]}];
        [periodToVisitors addObject:@{StatsPointNameKey: d[0], StatsPointCountKey: d[2]}];
    }];
    
    _viewsVisitorsData[@(unit)] = @{StatsViewsCategory: periodToViews,
                                    StatsVisitorsCategory: periodToVisitors};
}

- (NSDictionary *)viewsVisitorsForUnit:(StatsViewsVisitorsUnit)unit {
    return _viewsVisitorsData[@(unit)];
}

@end
