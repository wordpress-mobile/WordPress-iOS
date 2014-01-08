//
//  StatsVisits.m
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "StatsVisits.h"

@implementation StatsVisits

+ (NSArray *)visitsFromData:(NSDictionary *)visits siteId:(NSNumber *)siteId {
    NSMutableArray *visitList = [[NSMutableArray alloc] init];
    for (NSArray *visit in visits[@"data"]) {
        StatsVisits *statsVisit = [[StatsVisits alloc] initWithVisits:visit unit:visits[@"unit"] siteId:siteId];
        [visitList addObject:statsVisit];
    }
    return visitList;
}

- (id)initWithVisits:(NSArray *)visits unit:(NSString *)unit siteId:(NSNumber *)siteId {
    self = [super init];
    if (self) {
        self.siteId = siteId;
        self.period = visits[0];
        self.views = visits[1];
        self.visitors = visits[2];
        
        if ([unit isEqualToString:@"day"]) {
            self.unit = TimeUnitDay;
        } else if ([unit isEqualToString:@"week"]) {
            self.unit = TimeUnitWeek;
        } else if ([unit isEqualToString:@"month"]) {
            self.unit = TimeUnitMonth;
        }
    }
    return self;
}

@end
