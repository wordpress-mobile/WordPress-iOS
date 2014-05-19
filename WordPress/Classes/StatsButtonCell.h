#import "StatsViewController.h"
#import "WPTableViewCell.h"

@protocol StatsButtonCellDelegate;

@interface StatsButtonCell : WPTableViewCell

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, weak) id<StatsButtonCellDelegate> delegate;

+ (CGFloat)heightForRow;

- (void)addSegmentWithTitle:(NSString *)title;
- (void)segmentChanged:(UISegmentedControl *)sender;

@end

@protocol StatsButtonCellDelegate  <NSObject>

- (void)statsButtonCell:(StatsButtonCell *)statsButtonCell didSelectIndex:(NSUInteger)index;

@end