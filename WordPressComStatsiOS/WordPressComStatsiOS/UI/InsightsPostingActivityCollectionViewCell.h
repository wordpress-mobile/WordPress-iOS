#import <UIKit/UIKit.h>
#import "WPStatsContributionGraph.h"

@interface InsightsPostingActivityCollectionViewCell : UICollectionViewCell <WPStatsContributionGraphDelegate>

@property (weak, nonatomic) IBOutlet WPStatsContributionGraph *contributionGraph;

@end
