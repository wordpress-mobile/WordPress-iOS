#import <UIKit/UIKit.h>
#import "WPStatsViewsVisitors.h"

@interface WPStatsGraphViewController : UICollectionViewController

@property (nonatomic, strong) WPStatsViewsVisitors *viewsVisitors;
@property (nonatomic, assign) WPStatsViewsVisitorsUnit currentUnit;

@end
