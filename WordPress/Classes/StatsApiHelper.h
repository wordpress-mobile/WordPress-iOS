#import <Foundation/Foundation.h>

@class StatsSummary, StatsViewsVisitors, WPAccount;

@interface StatsApiHelper : NSObject

- (id)initWithSiteID:(NSNumber *)siteID andAccount:(WPAccount *)account;

- (void)fetchSummaryWithSuccess:(void (^)(StatsSummary *summary))success failure:(void (^)(NSError *error))failure;
- (void)fetchTopPostsWithSuccess:(void (^)(NSDictionary *topPosts))success failure:(void (^)(NSError *error))failure;
- (void)fetchClicksWithSuccess:(void (^)(NSDictionary *clicks))success failure:(void (^)(NSError *error))failure;
- (void)fetchCountryViewsWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
- (void)fetchReferrerWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
- (void)fetchSearchTermsWithSuccess:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
- (void)fetchViewsVisitorsWithSuccess:(void (^)(StatsViewsVisitors *))success failure:(void (^)(NSError *))failure;

@end
