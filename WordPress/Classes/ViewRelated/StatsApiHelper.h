#import <Foundation/Foundation.h>

@class StatsSummary, StatsViewsVisitors, WPAccount;

@interface StatsApiHelper : NSObject

- (id)initWithSiteID:(NSNumber *)siteID andAccount:(WPAccount *)account;

- (void)fetchSummaryWithSuccess:(void (^)(StatsSummary *summary))success failure:(void (^)(NSError *error))failure;
- (void)fetchTopPostsWithSuccess:(void (^)(NSDictionary *topPosts))success failure:(void (^)(NSError *error))failure;
- (void)fetchClicksWithSuccess:(void (^)(NSDictionary *clicks))success failure:(void (^)(NSError *error))failure;
- (void)fetchCountryViewsWithSuccess:(void (^)(NSDictionary *countryViews))success failure:(void (^)(NSError *error))failure;
- (void)fetchReferrerWithSuccess:(void (^)(NSDictionary *referrers))success failure:(void (^)(NSError *error))failure;
- (void)fetchSearchTermsWithSuccess:(void (^)(NSDictionary *searchTerms))success failure:(void (^)(NSError *error))failure;
- (void)fetchViewsVisitorsWithSuccess:(void (^)(StatsViewsVisitors *viewsVisitors))success failure:(void (^)(NSError *error))failure;
@end
