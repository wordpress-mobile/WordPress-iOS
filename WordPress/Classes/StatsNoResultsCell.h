/*
 * StatsNoResultsCell.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "StatsViewController.h"
#import "WPTableViewCell.h"

@interface StatsNoResultsCell : WPTableViewCell

+ (CGFloat)heightForRowForSection:(StatsSection)section withWidth:(CGFloat)width;

- (void)configureForSection:(StatsSection)section;

@end