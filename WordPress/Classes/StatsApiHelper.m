/*
 * StatsApiHelper.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsApiHelper.h"
#import "WordPressComApi.h"
#import "WPAccount.h"
#import "StatsSummary.h"
#import "StatsTopPost.h"
#import "StatsTitleCountItem.h"
#import "StatsClickGroup.h"
#import "StatsReferrerGroup.h"
#import "StatsTitleCountItem.h"

@interface StatsApiHelper ()

@property (nonatomic, strong) NSString *statsPathPrefix;
@property (nonatomic, weak) WordPressComApi *api;
@property (nonatomic, strong) NSDateFormatter *formatter;
@property (nonatomic, strong) NSNumber *siteID;

@end

@implementation StatsApiHelper

- (id)initWithSiteID:(NSNumber *)siteID {
    self = [super init];
    if (self) {
        _statsPathPrefix = [NSString stringWithFormat:@"sites/%@/stats", siteID];
        _siteID = siteID;
        _api = [[WPAccount defaultWordPressComAccount] restApi];
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.dateFormat = @"yyyy-MM-dd";
    }
    return self;
}

- (void)fetchSummaryWithSuccess:(void (^)(StatsSummary *))success failure:(void (^)(NSError *))failure {
    [_api getPath:_statsPathPrefix parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        StatsSummary *summary = [[StatsSummary alloc] initWithData:responseObject withSiteId:_siteID];
        success(summary);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)fetchStatsForPath:(NSString *)path success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    
    [_api getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
        return;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
        return;
    }];
}

- (void)fetchClicksWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    NSDate *today = [NSDate date];
    NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:-24*3600];
    
    NSString *todayPath = [NSString stringWithFormat:@"%@/clicks?date=%@", _statsPathPrefix, [self.formatter stringFromDate:today]];
    NSString *yesterdayPath = [NSString stringWithFormat:@"%@/clicks?date=%@", _statsPathPrefix, [self.formatter stringFromDate:yesterday]];
    
    [self fetchStatsForPath:todayPath success:^(NSDictionary *todaysData) {
        [self fetchStatsForPath:yesterdayPath success:^(NSDictionary *yesterdaysData) {
            NSArray *todayClickGroups = [StatsClickGroup clickGroupsFromData:todaysData withSiteId:self.siteID];
            NSArray *yesterdayClickGroups = [StatsClickGroup clickGroupsFromData:yesterdaysData withSiteId:self.siteID];
            success(@{@"today": todayClickGroups, @"yesterday": yesterdayClickGroups});
        } failure:failure];
    } failure:failure];
}
                                             
- (void)fetchCountryViewsForDate:(NSDate *)date success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    NSString *path = [NSString stringWithFormat:@"%@/country-views?date=%@", _statsPathPrefix, [self.formatter stringFromDate:date]];
    [self fetchStatsForPath:path success:success failure:failure];
}

- (void)fetchReferrersForDate:(NSDate *)date success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    
    NSDate *today = [NSDate date];
    NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:-24*3600];
    
    NSString *todayPath = [NSString stringWithFormat:@"%@/referrers?date=%@", _statsPathPrefix, [self.formatter stringFromDate:today]];
    NSString *yesterdayPath = [NSString stringWithFormat:@"%@/referrers?date=%@", _statsPathPrefix, [self.formatter stringFromDate:yesterday]];
    
    [self fetchStatsForPath:todayPath success:^(NSDictionary *todaysData) {
        [self fetchStatsForPath:yesterdayPath success:^(NSDictionary *yesterdaysData) {
            NSArray *todayReferrerGroups = [StatsReferrerGroup referrerGroupsFromData:todaysData withSiteId:self.siteID];
            NSArray *yesterdayReferrerGroup = [StatsReferrerGroup referrerGroupsFromData:yesterdaysData withSiteId:self.siteID];
            
            success(@{@"today":todayReferrerGroups,@"yesterday":yesterdayReferrerGroup});
        } failure:failure];
    }failure:failure];
}

- (void)fetchSearchTermsForDate:(NSDate *)date success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    
    NSDate *today = [NSDate date];
    NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:-24*3600];
    
    NSString *todayPath = [NSString stringWithFormat:@"%@/search-terms?date=%@", _statsPathPrefix, [self.formatter stringFromDate:today]];
    NSString *yesterdayPath = [NSString stringWithFormat:@"%@/search-terms?date=%@", _statsPathPrefix, [self.formatter stringFromDate:yesterday]];
    
    [self fetchStatsForPath:todayPath success:^(NSDictionary *todayData) {
        [self fetchStatsForPath:yesterdayPath success:^(NSDictionary *yesterdayData) {
            NSArray *todaySearchTerms = [StatsTitleCountItem titleCountItemsFromData:todayData withKey:@"search-terms" siteId:self.siteID];
            NSArray *yesterdaySearchTerms = [StatsTitleCountItem titleCountItemsFromData:yesterdayData withKey:@"search-terms" siteId:self.siteID];
            
            success(@{@"today":todaySearchTerms,@"yesterday":yesterdaySearchTerms});
        } failure:failure];
    }failure:failure];
}

- (void)fetchTopPostsWithSuccess:(void (^)(NSDictionary *topPosts))success failure:(void (^)(NSError *error))failure {
    NSString *yesterdayPath = [NSString stringWithFormat:@"%@/top-posts?date=%@", _statsPathPrefix, [self.formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-24*3600]]];
    NSString *todayPath = [NSString stringWithFormat:@"%@/top-posts?date=%@", _statsPathPrefix, [self.formatter stringFromDate:[NSDate date]]];
    
    [self fetchStatsForPath:yesterdayPath success:^(NSDictionary *yesterdayData) {
        [self fetchStatsForPath:todayPath success:^(NSDictionary *todayData) {
        
            success([StatsTopPost postsFromTodaysData:todayData yesterdaysData:yesterdayData siteId:self.siteID]);

        } failure:^(NSError *e) {
            failure(e);
        }];
        
    } failure:^(NSError *e) {
        failure(e);
    }];
}

- (void)fetchBarChartDataWithUnit:(NSString *)unit quantity:(NSNumber *)quantity success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    NSString *path = [NSString stringWithFormat:@"%@/visits?unit=%@&quantity=%@", _statsPathPrefix, unit, quantity];
    [self fetchStatsForPath:path success:success failure:failure];
}

@end
