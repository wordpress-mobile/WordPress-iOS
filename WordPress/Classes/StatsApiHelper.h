/*
 * StatsApiHelper.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

@interface StatsApiHelper : NSObject

- (id)initWithSiteID:(NSNumber *)siteID;

- (void)fetchSummaryWithSuccess:(void (^)(NSDictionary *summary))success failure:(void (^)(NSError *error))failure;

- (void)fetchClicksForDate:(NSDate *)date success:(void (^)(NSDictionary *clicks))success failure:(void (^)(NSError *error))failure;
- (void)fetchCountryViewsForDate:(NSDate *)date success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
- (void)fetchReferrersForDate:(NSDate *)date success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
- (void)fetchSearchTermsForDate:(NSDate *)date success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
- (void)fetchTopPostsWithSuccess:(void (^)(NSDictionary *topPosts))success failure:(void (^)(NSError *error))failure;

- (void)fetchBarChartDataWithUnit:(NSString *)unit quantity:(NSNumber *)quantity success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;

@end
