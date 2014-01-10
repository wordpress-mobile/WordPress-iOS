//
//  StatsReferrer.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-07.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsTitleCountItem.h"

@interface StatsReferrer : StatsTitleCountItem

+ (NSArray *)referrersFromArray:(NSArray *)referrers siteId:(NSNumber *)siteId;

@end
