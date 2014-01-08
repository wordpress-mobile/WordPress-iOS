//
//  StatClick.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsTitleCountItem.h"

@interface StatsClick : StatsTitleCountItem

@property (nonatomic, strong) NSString *url;

+ (NSArray *)clicksFromArray:(NSArray *)clicks withDate:(NSDate *)date siteId:(NSNumber *)siteId;

@end
