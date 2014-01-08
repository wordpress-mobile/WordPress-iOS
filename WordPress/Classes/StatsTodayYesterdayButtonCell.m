//
//  StatsTodayYesterdayButtonCell.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-07.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsTodayYesterdayButtonCell.h"

@interface StatsTodayYesterdayButtonCell ()

@property (nonatomic, weak) id<StatsTodayYesterdayButtonCellDelegate> delegate;

@end

@implementation StatsTodayYesterdayButtonCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self addButtonWithTitle:NSLocalizedString(@"Today", @"Select today's data for a stats section") target:self action:@selector(daySelected:) section:0];
        [self addButtonWithTitle:NSLocalizedString(@"Yesterday", @"Select yesterday's data for a stats section") target:self action:@selector(daySelected:) section:0];
    }
    return self;
}

- (void)setupForSection:(StatsSection)section delegate:(id<StatsTodayYesterdayButtonCellDelegate>)delegate todayActive:(BOOL)todayActive {
    self.delegate = delegate;
    [self.buttons[0] setTag:section];
    [self.buttons[1] setTag:section];
    [self activateButton:self.buttons[(todayActive ? 0 : 1)]];
}

- (void)daySelected:(UIButton *)sender {
    BOOL todaySelected = (self.buttons[0] == sender);
    [self.delegate statsDayChangedForSection:sender.tag todaySelected:todaySelected];
}

- (void)prepareForReuse {
    // Subclass
    // Don't remove the buttons
}

@end
