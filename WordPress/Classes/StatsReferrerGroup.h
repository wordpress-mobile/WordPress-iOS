/*
 * StatsReferrerGroup.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>
#import "StatsGroup.h"

@interface StatsReferrerGroup : StatsGroup

@property (nonatomic, strong) NSArray *referrers;

+ (NSArray *)referrerGroupsFromData:(NSDictionary *)resultGroups withSiteId:(NSNumber *)siteId;

@end
