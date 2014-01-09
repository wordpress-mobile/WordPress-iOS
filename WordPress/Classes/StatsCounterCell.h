/*
 * StatsCounterCell.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

@interface StatsCounterCell : WPTableViewCell

+ (CGFloat)heightForRow;

- (void)setTitle:(NSString *)title;
- (void)addCount:(NSNumber *)count withLabel:(NSString *)label;

@end
