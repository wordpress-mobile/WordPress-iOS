#import "StatsButtonCell.h"

@protocol StatsTodayYesterdayButtonCellDelegate <NSObject>

- (void)statsDayChangedForSection:(StatsSection)section todaySelected:(BOOL)todaySelected;

@end

@interface StatsTodayYesterdayButtonCell : StatsButtonCell

- (void)setupForSection:(StatsSection)section delegate:(id<StatsTodayYesterdayButtonCellDelegate>)delegate todayActive:(BOOL)todayActive;

@end
