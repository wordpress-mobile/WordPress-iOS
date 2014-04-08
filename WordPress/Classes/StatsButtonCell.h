#import "StatsViewController.h"
#import "WPTableViewCell.h"

@protocol StatsButtonCellDelegate;

@interface StatsButtonCell : WPTableViewCell

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, weak) id<StatsButtonCellDelegate> delegate;

+ (CGFloat)heightForRow;

//- (void)addButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action section:(StatsSection)section;

- (void)addSegmentWithTitle:(NSString *)title;
- (void)segmentChanged:(UISegmentedControl *)sender;

@end

@protocol StatsButtonCellDelegate  <NSObject>

- (void)statsButtonCell:(StatsButtonCell *)statsButtonCell didSelectIndex:(NSUInteger)index;

@end