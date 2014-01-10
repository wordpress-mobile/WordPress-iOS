//
//  StatsReferrer.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-07.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsReferrer.h"

@implementation StatsReferrer

+ (NSArray *)referrersFromArray:(NSArray *)results siteId:(NSNumber *)siteId {
    NSMutableArray *referrerList = [NSMutableArray array];
    for (NSArray *referrer in results) {
        StatsReferrer *r = [[StatsReferrer alloc] init];
        r.title = referrer[0];
        r.url = referrer[0];
        r.count = referrer[1];
        r.siteId = siteId;
        [referrerList addObject:r];
    }
    return referrerList;
}

@end
