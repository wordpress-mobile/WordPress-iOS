/*
 * StatsBarGraphCell.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

typedef NS_ENUM(NSInteger, StatsViewsVisitorsUnit) {
    StatsViewsVisitorsUnitDay,
    StatsViewsVisitorsUnitWeek,
    StatsViewsVisitorsUnitMonth
};

extern NSString *const StatsViewsCategory;
extern NSString *const StatsVisitorsCategory;

@interface StatsViewsVisitorsBarGraphCell : WPTableViewCell

+ (CGFloat)heightForRow;

- (void)setData:(NSArray *)data forUnit:(StatsViewsVisitorsUnit)unit category:(NSString *)category;
- (void)showGraphForUnit:(StatsViewsVisitorsUnit)unit;

@end
