//
//  StatClickGroup.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StatsGroup.h"

@interface StatsClickGroup : StatsGroup


@property (nonatomic, strong) NSArray *clicks;

+ (NSArray *)clickGroupsFromData:(NSDictionary *)clickGroups withSiteId:(NSNumber *)siteId;

@end
