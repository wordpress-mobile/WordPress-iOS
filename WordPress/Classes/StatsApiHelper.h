/*
 * StatsApiHelper.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

@class StatsSummary, StatsViewsVisitors;

@interface StatsApiHelper : NSObject

- (id)initWithSiteID:(NSNumber *)siteID;

- (void)fetchSummaryWithSuccess:(void (^)(StatsSummary *summary))success failure:(void (^)(NSError *error))failure;
- (void)fetchTopPostsWithSuccess:(void (^)(NSDictionary *topPosts))success failure:(void (^)(NSError *error))failure;
- (void)fetchClicksWithSuccess:(void (^)(NSDictionary *clicks))success failure:(void (^)(NSError *error))failure;
- (void)fetchCountryViewsWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
- (void)fetchReferrerWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
- (void)fetchSearchTermsWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
- (void)fetchViewsVisitorsWithSuccess:(void (^)(StatsViewsVisitors *))success failure:(void (^)(NSError *))failure;

@end
