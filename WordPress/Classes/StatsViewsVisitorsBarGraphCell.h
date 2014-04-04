#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"
#import "StatsViewsVisitors.h"

@interface StatsViewsVisitorsBarGraphCell : WPTableViewCell

+ (CGFloat)heightForRow;

- (void)setViewsVisitors:(StatsViewsVisitors *)viewsVisitors;
- (void)showGraphForUnit:(StatsViewsVisitorsUnit)unit;

@end
