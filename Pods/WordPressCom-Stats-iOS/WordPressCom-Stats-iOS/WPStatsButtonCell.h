#import <UIKit/UIKit.h>
#import "WPStatsViewController.h"
#import <WPTableViewCell.h>

@protocol StatsButtonCellDelegate;

@interface WPStatsButtonCell : WPTableViewCell

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, weak) id<StatsButtonCellDelegate> delegate;

+ (CGFloat)heightForRow;

- (void)addSegmentWithTitle:(NSString *)title;
- (void)segmentChanged:(UISegmentedControl *)sender;

@end

@protocol StatsButtonCellDelegate  <NSObject>

- (void)statsButtonCell:(WPStatsButtonCell *)statsButtonCell didSelectIndex:(NSUInteger)index;

@end