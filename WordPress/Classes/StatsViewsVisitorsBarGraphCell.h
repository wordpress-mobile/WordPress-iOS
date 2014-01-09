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

<<<<<<< HEAD:WordPress/Classes/StatsBarGraphCell.h
@interface StatsBarGraphCell : WPTableViewCell
=======
@interface StatsViewsVisitorsBarGraphCell : UITableViewCell
>>>>>>> Stats views/visitor basic chart:WordPress/Classes/StatsViewsVisitorsBarGraphCell.h

+ (CGFloat)heightForRow;

- (void)setGraphData:(NSDictionary *)graphData;

@end
