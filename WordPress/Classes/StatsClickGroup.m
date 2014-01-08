//
//  StatClickGroup.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsClickGroup.h"
#import "StatsClick.h"

@implementation StatsClickGroup


+(NSArray *)clickGroupsFromData:(NSDictionary *)clickGroups withSiteId:(NSNumber *)siteId {
    NSDictionary *clicks = clickGroups[@"clicks"];
    NSMutableArray *clickGroupList = [NSMutableArray array];
    for (NSDictionary *clickGroup in clicks) {
        StatsClickGroup *cg = [[StatsClickGroup alloc] init];
        cg.group = clickGroup[@"group"];
        cg.title = clickGroup[@"name"];
        cg.iconUrl = clickGroup[@"icon"];
        cg.count = clickGroup[@"total"];
        cg.date = clickGroups[@"date"];
        cg.siteId = siteId;
        cg.clicks = [StatsClick clicksFromArray:clickGroup[@"results"] withDate:cg.date siteId:siteId];
        [clickGroupList addObject:cg];
    }
    return clickGroupList;
}

@end
