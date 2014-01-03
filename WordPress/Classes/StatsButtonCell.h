/*
 * StatsButtonCell.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>

@interface StatsButtonCell : UITableViewCell

+ (CGFloat)heightForRow;

- (void)addButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;

@end
