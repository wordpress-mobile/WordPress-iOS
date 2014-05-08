#import <Foundation/Foundation.h>
#import "StatsSummary.h"
#import "StatsViewsVisitors.h"

typedef void (^StatsCompletion)(StatsSummary *summary, NSDictionary *topPosts, NSDictionary *clicks, NSDictionary *countryViews, NSDictionary *referrers, NSDictionary *searchTerms, StatsViewsVisitors *viewsVisitors);

@class WPAccount;

@interface WPStatsService : NSObject

- (instancetype)initWithSiteId:(NSNumber *)siteId andAccount:(WPAccount *)account;

- (void)retrieveStatsWithCompletionHandler:(StatsCompletion)completion failureHandler:(void (^)(NSError *error))failureHandler;

@end