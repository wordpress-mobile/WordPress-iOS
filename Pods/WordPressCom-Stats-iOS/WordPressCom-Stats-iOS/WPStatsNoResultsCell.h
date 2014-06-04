#import <UIKit/UIKit.h>
#import "WPStatsViewController.h"

@interface WPStatsNoResultsCell : UITableViewCell

+ (CGFloat)heightForRowForSection:(StatsSection)section withWidth:(CGFloat)width;

- (void)configureForSection:(StatsSection)section;

@end