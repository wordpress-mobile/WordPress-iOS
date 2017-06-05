#import <UIKit/UIKit.h>
#import "StatsVisits.h"
#import "StatsSummary.h"

@protocol WPStatsGraphViewControllerDelegate;

@interface WPStatsGraphViewController : UICollectionViewController

@property (nonatomic, weak) id<WPStatsGraphViewControllerDelegate> graphDelegate;
@property (nonatomic, assign) BOOL allowDeselection; // defaults to YES


- (void)setVisits:(StatsVisits *)visits forSummaryType:(StatsSummaryType)summaryType withSelectedDate:(NSDate *)selectedDate;
- (void)selectGraphBarWithDate:(NSDate *)selectedDate;

@end

@protocol WPStatsGraphViewControllerDelegate <NSObject>

@optional

- (BOOL)statsGraphViewController:(WPStatsGraphViewController *)controller shouldSelectDate:(NSDate *)date;
- (void)statsGraphViewController:(WPStatsGraphViewController *)controller didSelectDate:(NSDate *)date;
- (void)statsGraphViewControllerDidDeselectAllBars:(WPStatsGraphViewController *)controller;

@end
