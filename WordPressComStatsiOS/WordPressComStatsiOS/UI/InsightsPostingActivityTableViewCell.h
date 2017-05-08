#import <UIKit/UIKit.h>
#import "StatsStandardBorderedTableViewCell.h"
#import "WPStatsContributionGraph.h"

@interface InsightsPostingActivityTableViewCell : StatsStandardBorderedTableViewCell <WPStatsContributionGraphDelegate>

@property (nonatomic, assign) BOOL selectable;
@property (nonatomic, weak) IBOutlet WPStatsContributionGraph *contributionGraphLeft;
@property (nonatomic, weak) IBOutlet WPStatsContributionGraph *contributionGraphCenter;
@property (nonatomic, weak) IBOutlet WPStatsContributionGraph *contributionGraphRight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightConstraint;

- (void)doneSettingProperties;

@end
