#import <UIKit/UIKit.h>
#import "WPStatsViewController.h"
#import <WPTableViewCell.h>

@interface WPStatsNoResultsCell : WPTableViewCell

+ (CGFloat)heightForRowForSection:(StatsSection)section withWidth:(CGFloat)width;

- (void)configureForSection:(StatsSection)section;

@end