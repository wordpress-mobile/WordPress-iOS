#import <UIKit/UIKit.h>
#import "StatsTableViewController.h"
#import "WPStatsService.h"
@import WordPressKit;

typedef NS_ENUM(NSInteger, StatsPeriodType)
{
    StatsPeriodTypeInsights,
    StatsPeriodTypeDays,
    StatsPeriodTypeWeeks,
    StatsPeriodTypeMonths,
    StatsPeriodTypeYears
};

@class WPStatsViewController;

@protocol WPStatsSummaryTypeSelectionDelegate <NSObject>

- (void)viewController:(UIViewController *)viewController changeStatsSummaryTypeSelection:(StatsSummaryType)statsSummaryType;

@end

@protocol WPStatsViewControllerDelegate <NSObject>

@optional

- (void)statsViewController:(WPStatsViewController *)controller openURL:(NSURL *)url;
- (WPStatsService *)statsService;

@end

@protocol StatsProgressViewDelegate <NSObject>

- (void)statsViewControllerDidBeginLoadingStats:(UIViewController *)controller;
- (void)statsViewController:(UIViewController *)controller loadingProgressPercentage:(CGFloat)percentage;
- (void)statsViewControllerDidEndLoadingStats:(UIViewController *)controller;

@end

@interface WPStatsViewController : UIViewController

@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, copy)   NSString *oauth2Token;
@property (nonatomic, strong) NSTimeZone *siteTimeZone;
@property (nonatomic, strong) WPStatsService *statsService;
@property (nonatomic, weak) id<WPStatsViewControllerDelegate> statsDelegate;

- (IBAction)statsTypeControlDidChange:(UISegmentedControl *)control;

@end
