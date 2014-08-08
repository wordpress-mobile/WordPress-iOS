#import <UIKit/UIKit.h>
#import "WPStatsViewsVisitors.h"

@protocol WPStatsGraphViewControllerDelegate;

@interface WPStatsGraphViewController : UICollectionViewController

@property (nonatomic, weak) id<WPStatsGraphViewControllerDelegate> graphDelegate;
@property (nonatomic, strong) WPStatsViewsVisitors *viewsVisitors;
@property (nonatomic, assign) WPStatsViewsVisitorsUnit currentUnit;

@end

@protocol WPStatsGraphViewControllerDelegate <NSObject>

@optional

- (void)statsGraphViewController:(WPStatsGraphViewController *)controller didSelectData:(NSArray *)data withXLocation:(CGFloat)xLocation;
- (void)statsGraphViewControllerDidDeselectAllBars:(WPStatsGraphViewController *)controller;

@end
