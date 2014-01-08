//
//  StatsReferrer.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-07.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsTitleCountItem.h"

@interface StatsReferrer : StatsTitleCountItem

@property (nonatomic, strong) NSString *url;

+ (NSArray *)referrersFromArray:(NSArray *)referrers withDate:(NSDate *)date siteId:(NSNumber *)siteId;

@end
