/*
 * StatsSummary.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

@interface StatsSummary : NSObject

@property (nonatomic, strong) NSNumber *totalCategories;
@property (nonatomic, strong) NSNumber *totalComments;
@property (nonatomic, strong) NSNumber *totalFollowersBlog;
@property (nonatomic, strong) NSNumber *totalFollowersComments;
@property (nonatomic, strong) NSNumber *totalPosts;
@property (nonatomic, strong) NSNumber *totalShares;
@property (nonatomic, strong) NSNumber *totalTags;
@property (nonatomic, strong) NSNumber *totalViews;
@property (nonatomic, strong) NSNumber *viewCountBest;
@property (nonatomic, strong) NSNumber *viewCountToday;
@property (nonatomic, strong) NSNumber *visitorCountToday;

- (id)initWithData:(NSDictionary *)summary;

@end
