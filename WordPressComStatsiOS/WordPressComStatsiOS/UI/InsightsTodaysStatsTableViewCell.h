#import <UIKit/UIKit.h>
#import "StatsStandardBorderedTableViewCell.h"

@interface InsightsTodaysStatsTableViewCell : StatsStandardBorderedTableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *todayViewsImage;
@property (nonatomic, weak) IBOutlet UIImageView *todayVisitorsImage;
@property (nonatomic, weak) IBOutlet UIImageView *todayLikesImage;
@property (nonatomic, weak) IBOutlet UIImageView *todayCommentsImage;

@property (nonatomic, weak) IBOutlet UIButton *todayViewsButton;
@property (nonatomic, weak) IBOutlet UIButton *todayVisitorsButton;
@property (nonatomic, weak) IBOutlet UIButton *todayLikesButton;
@property (nonatomic, weak) IBOutlet UIButton *todayCommentsButton;

@property (nonatomic, weak) IBOutlet UIButton *todayViewsValueButton;
@property (nonatomic, weak) IBOutlet UIButton *todayVisitorsValueButton;
@property (nonatomic, weak) IBOutlet UIButton *todayLikesValueButton;
@property (nonatomic, weak) IBOutlet UIButton *todayCommentsValueButton;

@end
