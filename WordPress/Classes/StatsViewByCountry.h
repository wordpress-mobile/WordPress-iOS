/*
 * StatsViewByCountry.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsTitleCountItem.h"

@interface StatsViewByCountry : StatsTitleCountItem

@property (nonatomic, strong) NSURL *imageUrl;

+ (NSArray *)viewByCountryFromData:(NSDictionary *)countryData;

@end
