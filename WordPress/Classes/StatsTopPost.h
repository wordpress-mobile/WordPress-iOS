/*
 * StatsTopPost.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsTitleCountItem.h"

@interface StatsTopPost : StatsTitleCountItem

@property (nonatomic, strong) NSNumber *postID;

+ (NSDictionary *)postsFromTodaysData:(NSDictionary *)todaysData yesterdaysData:(NSDictionary *)yesterdaysData;

@end
