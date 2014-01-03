/*
 * StatsResultCell.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsTwoLabelCell.h"

@interface StatsResultCell : StatsTwoLabelCell

- (void)setResultTitle:(NSString *)title;
- (void)setResultCount:(NSNumber *)count;

@end
