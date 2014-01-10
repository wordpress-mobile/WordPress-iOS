//
//  StatClick.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsTitleCountItem.h"

@interface StatsClick : StatsTitleCountItem

+ (NSArray *)clicksFromArray:(NSArray *)clicks siteId:(NSNumber *)siteId;

@end
