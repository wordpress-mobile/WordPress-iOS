//
//  StatsTopPost.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StatsTitleCountItem.h"

@interface StatsTopPost : StatsTitleCountItem

@property (nonatomic, strong) NSNumber *postID;

+ (NSDictionary *)postsFromTodaysData:(NSDictionary *)todaysData yesterdaysData:(NSDictionary *)yesterdaysData siteId:(NSNumber *)siteId;

- (id)initTopPost:(NSDictionary *)posts withSiteId:(NSNumber *)siteId;

@end
