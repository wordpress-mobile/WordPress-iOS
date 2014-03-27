//
//  StatsGroup.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-07.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsGroup.h"

@implementation StatsGroup

+ (NSArray *)groupsFromData:(NSArray *)groups {
    NSMutableArray *groupList = [NSMutableArray array];
    for (NSDictionary *group in groups) {
        StatsGroup *rg = [[self alloc] init];
        rg.title = [group stringForKey:@"name"];
        rg.iconUrl = [NSURL URLWithString:[group stringForKey:@"icon"]];
        rg.count = [group numberForKey:@"total"];
        [rg addChildrenFromArray:[group arrayForKey:@"results"]];
        [groupList addObject:rg];
    }
    return groupList;
}

- (void)addChildrenFromArray:(NSArray *)results {
    NSMutableArray *children = [NSMutableArray array];
    for (NSArray *c in results) {
        StatsTitleCountItem *r = [[StatsTitleCountItem alloc] init];
        r.title = c[0];
        r.URL = [NSURL URLWithString:c[0]];
        r.count = c[1];
        [children addObject:r];
    }
    self.children = children;
}

@end
