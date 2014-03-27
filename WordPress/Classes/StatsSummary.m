/*
 * StatsSummary.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsSummary.h"

@implementation StatsSummary

- (id)initWithData:(NSDictionary *)summary {
    self = [super init];
    if (self) {
        NSDictionary *stats = summary[@"stats"];
        self.totalCategories = stats[@"categories"];
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
