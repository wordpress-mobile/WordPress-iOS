/*
 * StatsButtonCell.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsViewController.h"
#import "WPTableViewCell.h"

@interface StatsButtonCell : WPTableViewCell

@property (nonatomic, strong) NSMutableArray *buttons;

+ (CGFloat)heightForRow;

- (void)addButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action section:(StatsSection)section;
- (void)activateButton:(UIButton *)button;

@end
