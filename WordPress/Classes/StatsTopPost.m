//
//  StatsTopPost.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsTopPost.h"

@implementation StatsTopPost

+ (NSDictionary *)postsFromTodaysData:(NSDictionary *)todaysData yesterdaysData:(NSDictionary *)yesterdaysData siteId:(NSNumber *)siteId {
    NSMutableArray *todayPostList = [NSMutableArray array];
    for (NSDictionary *post in todaysData[@"top-posts"]) {
        StatsTopPost *topPost = [[StatsTopPost alloc] initTopPost:post withSiteId:siteId];
        [todayPostList addObject:topPost];
    }
    NSMutableArray *yesterdayPostList = [NSMutableArray array];
    for (NSDictionary *post in yesterdaysData[@"top-posts"]) {
        StatsTopPost *topPost = [[StatsTopPost alloc] initTopPost:post withSiteId:siteId];
        [yesterdayPostList addObject:topPost];
    }

    return @{@"today": todayPostList, @"yesterday": yesterdayPostList};
}

- (id)initTopPost:(NSDictionary *)post withSiteId:(NSNumber *)siteId {
    self = [super init];
    if (self) {
        self.title = post[@"title"];
        self.url = post[@"url"];
        self.count = post[@"views"];
    }
    return self;
}

@end
