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
#import "StatsTitleCountItem.h"
#import "StatsViewByCountry.h"
#import "StatsViewsVisitors.h"
#import "StatsGroup.h"

@interface StatsApiHelper ()

@property (nonatomic, strong) NSString *statsPathPrefix;
@property (nonatomic, weak) WordPressComApi *api;
@property (nonatomic, strong) NSDateFormatter *formatter;

@end

@implementation StatsApiHelper

- (id)initWithSiteID:(NSNumber *)siteID {
    self = [super init];
    if (self) {
        _statsPathPrefix = [NSString stringWithFormat:@"sites/%@/stats", siteID];
        _api = [[WPAccount defaultWordPressComAccount] restApi];
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.dateFormat = @"yyyy-MM-dd";
    }
    return self;
}

- (void)fetchSummaryWithSuccess:(void (^)(StatsSummary *))success failure:(void (^)(NSError *))failure {
    [_api getPath:_statsPathPrefix parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        StatsSummary *summary = [[StatsSummary alloc] initWithData:responseObject];
        success(summary);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)fetchClicksWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    [self fetchTodayYesterdayStatsForPath:@"clicks?date=" success:^(id todayData, id yesterdayData) {
        success(@{@"today": [StatsGroup groupsFromData:todayData[@"clicks"]],
                  @"yesterday": [StatsGroup groupsFromData:yesterdayData[@"clicks"]]});
    } failure:failure];
}
                                             
- (void)fetchCountryViewsWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    [self fetchTodayYesterdayStatsForPath:@"country-views?date=" success:^(id todayData, id yesterdayData) {
        success(@{@"today": [StatsViewByCountry viewByCountryFromData:todayData],
                  @"yesterday": [StatsViewByCountry viewByCountryFromData:yesterdayData]});
    } failure:failure];
}

- (void)fetchReferrerWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    [self fetchTodayYesterdayStatsForPath:@"referrers?date=" success:^(id todayData, id yesterdayData) {
        success(@{@"today": [StatsGroup groupsFromData:todayData[@"referrers"]],
                  @"yesterday": [StatsGroup groupsFromData:yesterdayData[@"referrers"]]});
    } failure:failure];
}

- (void)fetchSearchTermsWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    [self fetchTodayYesterdayStatsForPath:@"search-terms?date=" success:^(id todayData, id yesterdayData) {
        success(@{@"today": [StatsTitleCountItem titleCountItemsFromData:todayData[@"search-terms"]],
                  @"yesterday": [StatsTitleCountItem titleCountItemsFromData:yesterdayData[@"search-terms"]]});
    } failure:failure];
}

- (void)fetchTopPostsWithSuccess:(void (^)(NSDictionary *topPosts))success failure:(void (^)(NSError *error))failure {
    [self fetchTodayYesterdayStatsForPath:@"top-posts?date=" success:^(id todayData, id yesterdayData) {
        success([StatsTopPost postsFromTodaysData:todayData yesterdaysData:yesterdayData]);
    } failure:failure];
}

- (void)fetchTodayYesterdayStatsForPath:(NSString *)path success:(void (^)(id todayData, id yesterdayData))success failure:(void (^)(NSError *error))failure {
    NSString *yesterdayPath = [path stringByAppendingString:[self.formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-24*3600]]];
    NSString *todayPath = [path stringByAppendingString:[self.formatter stringFromDate:[NSDate date]]];
    [self fetchStatsForPath:todayPath success:^(id todaysData) {
        [self fetchStatsForPath:yesterdayPath success:^(id yesterdaysData) {
            success(todaysData, yesterdaysData);
        } failure:failure];
    } failure:failure];
}

- (void)fetchStatsForPath:(NSString *)path success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    [_api getPath:[_statsPathPrefix stringByAppendingPathComponent:path] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)fetchViewsVisitorsWithSuccess:(void (^)(StatsViewsVisitors *))success failure:(void (^)(NSError *))failure {
    NSArray *units = @[@"day", @"week", @"month"];
    StatsViewsVisitors *vv = [[StatsViewsVisitors alloc] init];
    [units enumerateObjectsUsingBlock:^(NSString *unit, NSUInteger idx, BOOL *stop) {
        NSString *path = [NSString stringWithFormat:@"visits?unit=%@&quantity=%d", unit, IS_IPAD ? 12 : 7];
        [self fetchStatsForPath:path success:^(NSDictionary *result) {
            [vv addViewsVisitorsWithData:result unit:idx];
            success(vv);
        } failure:failure];
    }];
}

@end
