/*
 * StatsReferrerGroup.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsReferrerGroup.h"
#import "StatsReferrer.h"

@implementation StatsReferrerGroup

+ (NSArray *)referrerGroupsFromData:(NSDictionary *)referrerGroups withSiteId:(NSNumber *)siteId {
    NSDictionary *referrers = referrerGroups[@"referrers"];
    NSMutableArray *referrerGroupList = [NSMutableArray array];
    for (NSDictionary *referrerGroup in referrers) {
        StatsReferrerGroup *rg = [[StatsReferrerGroup alloc] init];
        rg.group = referrerGroup[@"group"];
        rg.title = referrerGroup[@"name"];
        if (referrerGroup[@"icon"] != [NSNull null]) {
            rg.iconUrl = [NSURL URLWithString:referrerGroup[@"icon"]];
        }
        rg.count = referrerGroup[@"total"];
        rg.siteId = siteId;
        rg.referrers = [StatsReferrer referrersFromArray:referrerGroup[@"results"] siteId:siteId];
        [referrerGroupList addObject:rg];
    }
    return referrerGroupList;
}

@end
