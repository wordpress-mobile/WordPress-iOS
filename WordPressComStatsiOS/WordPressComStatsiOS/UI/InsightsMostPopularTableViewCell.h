#import <UIKit/UIKit.h>
#import "StatsStandardBorderedTableViewCell.h"

@interface InsightsMostPopularTableViewCell : StatsStandardBorderedTableViewCell

@property (nonatomic, weak) IBOutlet UILabel *mostPopularDayLabel;
@property (nonatomic, weak) IBOutlet UILabel *mostPopularDayPercentWeeklyViews;
@property (nonatomic, weak) IBOutlet UILabel *mostPopularHourLabel;
@property (nonatomic, weak) IBOutlet UILabel *mostPopularHourPercentDailyViews;
@property (nonatomic, weak) IBOutlet UILabel *mostPopularDay;
@property (nonatomic, weak) IBOutlet UILabel *mostPopularHour;

@end
