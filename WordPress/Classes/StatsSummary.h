//
//  StatsSummary.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//


@interface StatsSummary : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSNumber *totalCatagories;
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
