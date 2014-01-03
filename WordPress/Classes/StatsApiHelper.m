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

- (void)fetchSummaryWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    [_api getPath:_statsPathPrefix parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
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

- (void)fetchClicksForDate:(NSDate *)date success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    NSString *path = [NSString stringWithFormat:@"%@/clicks?date=%@", _statsPathPrefix, [self.formatter stringFromDate:date]];
    [self fetchStatsForPath:path success:success failure:failure];
}
                                             
- (void)fetchCountryViewsForDate:(NSDate *)date success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    NSString *path = [NSString stringWithFormat:@"%@/country-views?date=%@", _statsPathPrefix, [self.formatter stringFromDate:date]];
    [self fetchStatsForPath:path success:success failure:failure];
}

- (void)fetchReferrersForDate:(NSDate *)date success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    NSString *path = [NSString stringWithFormat:@"%@/referrers?date=%@", _statsPathPrefix, [self.formatter stringFromDate:date]];
    [self fetchStatsForPath:path success:success failure:failure];
}

- (void)fetchSearchTermsForDate:(NSDate *)date success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
    NSString *path = [NSString stringWithFormat:@"%@/search-terms?date=%@", _statsPathPrefix, [self.formatter stringFromDate:date]];
    [self fetchStatsForPath:path success:success failure:failure];
}

- (void)fetchTopPostsWithSuccess:(void (^)(NSDictionary *topPosts))success failure:(void (^)(NSError *error))failure {
    NSString *yesterdayPath = [NSString stringWithFormat:@"%@/top-posts?date=%@", _statsPathPrefix, [self.formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-24*3600]]];
    NSString *todayPath = [NSString stringWithFormat:@"%@/top-posts?date=%@", _statsPathPrefix, [self.formatter stringFromDate:[NSDate date]]];
    
    [self fetchStatsForPath:yesterdayPath success:^(NSDictionary *yesterdaysPosts) {
        [self fetchStatsForPath:todayPath success:^(NSDictionary *todaysPosts) {
          
            //Combine yesterday and today
            success(@{@"today": todaysPosts, @"yesterday": yesterdaysPosts});
            
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
