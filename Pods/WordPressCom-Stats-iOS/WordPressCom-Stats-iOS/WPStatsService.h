#import <Foundation/Foundation.h>
#import "WPStatsSummary.h"
#import "WPStatsViewsVisitors.h"

typedef void (^StatsCompletion)(WPStatsSummary *summary, NSDictionary *topPosts, NSDictionary *clicks, NSDictionary *countryViews, NSDictionary *referrers, NSDictionary *searchTerms, WPStatsViewsVisitors *viewsVisitors);

@class WPStatsServiceRemote;

@interface WPStatsService : NSObject

@property (nonatomic, strong) WPStatsServiceRemote *remote;

- (instancetype)initWithSiteId:(NSNumber *)siteId siteTimeZone:(NSTimeZone *)timeZone andOAuth2Token:(NSString *)oauth2Token;

- (void)retrieveStatsWithCompletionHandler:(StatsCompletion)completion failureHandler:(void (^)(NSError *error))failureHandler;

@end
