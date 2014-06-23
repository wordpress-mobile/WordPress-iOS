#import <UIKit/UIKit.h>
#import "WPStatsViewsVisitors.h"

@interface WPStatsViewsVisitorsBarGraphCell : UITableViewCell

+ (CGFloat)heightForRow;

- (void)setViewsVisitors:(WPStatsViewsVisitors *)viewsVisitors;
- (void)showGraphForUnit:(WPStatsViewsVisitorsUnit)unit;

@end
