//
//  StatClick.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsClick.h"

@implementation StatsClick

+ (NSArray *)clicksFromArray:(NSArray *)clicks siteId:(NSNumber *)siteId {
    NSMutableArray *clickList = [NSMutableArray array];
    for (NSArray *click in clicks) {
        StatsClick *c = [[StatsClick alloc] init];
        c.title = click[0]; // url/name
        c.url = click[0]; //remove?
        c.count = click[1];
        c.siteId = siteId;
        [clickList addObject:c];
    }
    return clickList;
}

@end
