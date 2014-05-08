#import <Foundation/Foundation.h>
#import "StatsSummary.h"
#import "StatsViewsVisitors.h"

typedef void (^StatsCompletion)(StatsSummary *summary, NSDictionary *topPosts, NSDictionary *clicks, NSDictionary *countryViews, NSDictionary *referrers, NSDictionary *searchTerms, StatsViewsVisitors *viewsVisitors);

@interface WPStatsService : NSObject

- (instancetype)initWithSiteId:(NSNumber *)siteId;

- (void)retrieveStatsWithCompletionHandler:(StatsCompletion)completion failureHandler:(void (^)(NSError *error))failureHandler;

@end