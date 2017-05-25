#import <UIKit/UIKit.h>
#import "WPStatsViewController.h"
#import "WPStatsService.h"
@import WordPressKit;

@protocol WPStatsViewControllerDelegate, StatsProgressViewDelegate;

@interface StatsTableViewController : UITableViewController

@property (nonatomic, strong) WPStatsService *statsService;
@property (nonatomic, weak) id<WPStatsViewControllerDelegate> statsDelegate;
@property (nonatomic, weak) id<StatsProgressViewDelegate> statsProgressViewDelegate;

- (void)changeGraphPeriod:(StatsPeriodUnit)toPeriod;
- (void)switchToSummaryType:(StatsSummaryType)summaryType;

@end
