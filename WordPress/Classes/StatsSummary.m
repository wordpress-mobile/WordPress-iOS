//
//  StatsSummary.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsSummary.h"

@implementation StatsSummary

- (id)initWithData:(NSDictionary *)summary withSiteId:(NSNumber *)siteId {
    self = [super init];
    if (self) {
        self.siteId = siteId;
        self.date = summary[@"day"];
        NSDictionary *stats = summary[@"stats"];
        self.totalCatagories = stats[@"categories"];
        self.totalComments = stats[@"comments"];
        self.totalFollowersBlog = stats[@"followers_blog"];
        self.totalFollowersComments = stats[@"followers_comments"];
        self.totalPosts = stats[@"posts"];
        self.totalShares = stats[@"shares"];
        self.totalTags = stats[@"tags"];
        self.totalViews = stats[@"views"];
        self.viewCountBest = stats[@"views_best_day_total"];
        self.viewCountToday = stats[@"views_today"];
        self.visitorCountToday = stats[@"visitors_today"];
    }
    return self;
}

@end
