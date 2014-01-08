//
//  StatsVisits.h
//  WordPress
//
//  Created by DX074-XL on 2014-01-06.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, TimeUnit) {
    TimeUnitDay,
    TimeUnitWeek,
    TimeUnitMonth
};

@class StatsSummary;

@interface StatsVisits : NSObject

@property (nonatomic, strong) NSNumber *siteId;
@property (nonatomic, strong) NSDate *period;//start date of the unit
@property (nonatomic, assign) TimeUnit unit;
@property (nonatomic, strong) NSNumber *views;
@property (nonatomic, strong) NSNumber *visitors;

+ (NSArray *)visitsFromData:(NSDictionary *)visits siteId:(NSNumber *)siteId;

- (id)initWithVisits:(NSArray *)visits unit:(NSString *)unit siteId:(NSNumber *)siteId;

@end
