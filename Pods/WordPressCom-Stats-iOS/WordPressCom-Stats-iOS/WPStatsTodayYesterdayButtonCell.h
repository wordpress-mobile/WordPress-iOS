#import "WPStatsButtonCell.h"

@protocol WPStatsTodayYesterdayButtonCellDelegate <NSObject>

- (void)statsDayChangedForSection:(StatsSection)section todaySelected:(BOOL)todaySelected;

@end

@interface WPStatsTodayYesterdayButtonCell : WPStatsButtonCell

- (void)setupForSection:(StatsSection)section delegate:(id<WPStatsTodayYesterdayButtonCellDelegate>)delegate todayActive:(BOOL)todayActive;

@end
