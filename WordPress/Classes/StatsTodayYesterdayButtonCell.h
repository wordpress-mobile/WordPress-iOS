//
//  StatsTodayYesterdayButtonCell.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-07.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsButtonCell.h"

@protocol StatsTodayYesterdayButtonCellDelegate <NSObject>

- (void)statsDayChangedForSection:(StatsSection)section todaySelected:(BOOL)todaySelected;

@end

@interface StatsTodayYesterdayButtonCell : StatsButtonCell

- (void)setupForSection:(StatsSection)section delegate:(id<StatsTodayYesterdayButtonCellDelegate>)delegate todayActive:(BOOL)todayActive;

@end
