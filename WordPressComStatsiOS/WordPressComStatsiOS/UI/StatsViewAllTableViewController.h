#import <UIKit/UIKit.h>
#import <WordPressKit/StatsSummary.h>
#import "WPStatsService.h"
#import "StatsSection.h"
#import "WPStatsViewController.h"

@interface StatsViewAllTableViewController : UITableViewController

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, assign) StatsPeriodUnit periodUnit;
@property (nonatomic, assign) StatsSection statsSection;
@property (nonatomic, assign) StatsSubSection statsSubSection;
@property (nonatomic, strong) WPStatsService *statsService;
@property (nonatomic, weak) id<WPStatsViewControllerDelegate> statsDelegate;

@end
