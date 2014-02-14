/*
 * StatsViewByCountry.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsViewByCountry.h"

@implementation StatsViewByCountry

+ (NSArray *)viewByCountryFromData:(NSDictionary *)countryData {
    NSArray *initialCountryList = countryData[@"country-views"];
    NSMutableArray *finalCountryList = [NSMutableArray array];
    for (NSDictionary *country in initialCountryList) {
        StatsViewByCountry *viewByCountry = [[StatsViewByCountry alloc] initWithCountry:country];
        [finalCountryList addObject:viewByCountry];
    }
    return finalCountryList;
}

- (id)initWithCountry:(NSDictionary *)country {
    self = [super init];
    if (self) {
        self.title = country[@"country"];
        self.count = country[@"views"];
        self.imageUrl = [[NSURL alloc] initWithString:country[@"imageUrl"]];
    }
    return self;
}

@end
