#import <UIKit/UIKit.h>
#import "StatsStandardBorderedTableViewCell.h"

@interface InsightsAllTimeTableViewCell : StatsStandardBorderedTableViewCell

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *heightConstraint;

@property (nonatomic, weak) IBOutlet UIImageView *allTimePostsImage;
@property (nonatomic, weak) IBOutlet UILabel *allTimePostsLabel;
@property (nonatomic, weak) IBOutlet UIImageView *allTimeViewsImage;
@property (nonatomic, weak) IBOutlet UILabel *allTimeViewsLabel;
@property (nonatomic, weak) IBOutlet UIImageView *allTimeVisitorsImage;
@property (nonatomic, weak) IBOutlet UILabel *allTimeVisitorsLabel;
@property (nonatomic, weak) IBOutlet UIImageView *allTimeBestViewsImage;
@property (nonatomic, weak) IBOutlet UILabel *allTimeBestViewsLabel;

@property (nonatomic, weak) IBOutlet UILabel *allTimePostsValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *allTimeViewsValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *allTimeVisitorsValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *allTimeBestViewsValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *allTimeBestViewsOnValueLabel;

@end
