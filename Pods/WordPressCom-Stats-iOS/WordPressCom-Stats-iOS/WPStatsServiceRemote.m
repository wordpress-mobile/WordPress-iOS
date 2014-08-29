#import "WPStatsServiceRemote.h"
#import "NSObject+SafeExpectations.h"
#import "NSDictionary+SafeExpectations.h"
#import "WPStatsGroup.h"
#import "WPStatsViewByCountry.h"
#import "WPStatsTitleCountItem.h"
#import "WPStatsTopPost.h"
#import <AFNetworking/AFNetworking.h>


static NSString *const WordPressComApiClientEndpointURL = @"https://public-api.wordpress.com/rest/v1";

@interface WPStatsServiceRemote ()

@property (nonatomic, copy) NSString *oauth2Token;
@property (nonatomic, strong) NSNumber *siteId;
@property (nonatomic, strong) NSTimeZone *siteTimeZone;
@property (nonatomic, copy) NSString *statsPathPrefix;

@end

@implementation WPStatsServiceRemote {

}

- (instancetype)initWithOAuth2Token:(NSString *)oauth2Token siteId:(NSNumber *)siteId andSiteTimeZone:(NSTimeZone *)timeZone
{
    NSAssert(oauth2Token.length > 0, @"OAuth2 token must not be empty.");
    NSAssert(siteId != nil, @"Site ID must not be nil.");
    NSAssert(timeZone != nil, @"Timezone must not be nil.");
    
    self = [super init];
    if (self) {
        _oauth2Token = oauth2Token;
        _siteId = siteId;
        _siteTimeZone = timeZone;
        _statsPathPrefix = [NSString stringWithFormat:@"/sites/%@/stats", _siteId];
    }

    return self;
}

- (void)fetchStatsForTodayDate:(NSDate *)today andYesterdayDate:(NSDate *)yesterday withCompletionHandler:(StatsCompletion)completionHandler failureHandler:(void (^)(NSError *error))failureHandler
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = self.siteTimeZone;

    NSString *todayString = [formatter stringFromDate:today];
    NSString *yesterdayString = [formatter stringFromDate:yesterday];

    NSArray *urls = @[
            [self urlForSummary],
            [self urlForClicksForDate:todayString],
            [self urlForClicksForDate:yesterdayString],
            [self urlForCountryViewsForDate:todayString],
            [self urlForCountryViewsForDate:yesterdayString],
            [self urlForReferrerForDate:todayString],
            [self urlForReferrerForDate:yesterdayString],
            [self urlForSearchTermsForDate:todayString],
            [self urlForSearchTermsForDate:yesterdayString],
            [self urlForTopPostsForDate:todayString],
            [self urlForTopPostsForDate:yesterdayString],
            [self urlForViewsVisitorsForUnit:@"day"],
            [self urlForViewsVisitorsForUnit:@"week"],
            [self urlForViewsVisitorsForUnit:@"month"],
    ];

    // This needs to eventually be replaced with an instance of WordPressComApi when it's decoupled from Core Data
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", self.oauth2Token]
                     forHTTPHeaderField:@"Authorization"];
    
    [manager GET:[self urlForBatch]
      parameters:@{ @"urls" : urls}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             if (![responseObject isKindOfClass:[NSDictionary class]]) {
                 if (failureHandler) {
                     NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                          code:NSURLErrorBadServerResponse
                                                      userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                     failureHandler(error);
                 }
                 
                 return;
             }
             
             NSDictionary *batch = (NSDictionary *)responseObject;
             
             WPStatsSummary *statsSummary;
             NSDictionary *statsSummaryDict = [batch dictionaryForKey:urls[0]];
             if (statsSummaryDict) {
                 statsSummary = [[WPStatsSummary alloc] initWithData:statsSummaryDict];
             }
             
             NSArray *clicksToday = @[];
             NSDictionary *clicksTodayDict = [batch dictionaryForKey:urls[1]];
             if (clicksTodayDict) {
                 clicksToday = [WPStatsGroup groupsFromData:clicksTodayDict[@"clicks"]];
             }
             
             NSArray *clicksYesterday = @[];
             NSDictionary *clicksYesterdayDict = [batch dictionaryForKey:urls[2]];
             if (clicksYesterdayDict) {
                 clicksYesterday = [WPStatsGroup groupsFromData:clicksYesterdayDict[@"clicks"]];
             }
             
             NSArray *countryViewsToday = @[];
             NSDictionary *countryViewsTodayDict = [batch dictionaryForKey:urls[3]];
             if (countryViewsTodayDict) {
                 countryViewsToday = [WPStatsViewByCountry viewByCountryFromData:countryViewsTodayDict];
             }
             
             NSArray *countryViewsYesterday = @[];
             NSDictionary *countryViewsYesterdayDict = [batch dictionaryForKey:urls[4]];
             if (countryViewsYesterdayDict) {
                 countryViewsYesterday = [WPStatsViewByCountry viewByCountryFromData:countryViewsYesterdayDict];
             }
             
             NSArray *referrersToday = @[];
             NSDictionary *referrersTodayDict = [batch dictionaryForKey:urls[5]];
             if (referrersTodayDict) {
                 referrersToday = [WPStatsGroup groupsFromData:referrersTodayDict[@"referrers"]];
             }
             
             NSArray *referrersYesterday = @[];
             NSDictionary *referrersYesterdayDict = [batch dictionaryForKey:urls[6]];
             if (referrersYesterdayDict) {
                 referrersYesterday = [WPStatsGroup groupsFromData:referrersYesterdayDict[@"referrers"]];
             }
             
             NSArray *searchTermsToday = @[];
             NSDictionary *searchTermsTodayDict = [batch dictionaryForKey:urls[7]];
             if (searchTermsTodayDict) {
                 searchTermsToday = [WPStatsTitleCountItem titleCountItemsFromData:searchTermsTodayDict[@"search-terms"]];
             }
             
             NSArray *searchTermsYesterday = @[];
             NSDictionary *searchTermsYesterdayDict = [batch dictionaryForKey:urls[8]];
             if (searchTermsYesterdayDict) {
                 searchTermsYesterday = [WPStatsTitleCountItem titleCountItemsFromData:searchTermsYesterdayDict[@"search-terms"]];
             }
             
             NSDictionary *topPosts = @{};
             NSDictionary *topPostsTodayDict = [batch dictionaryForKey:urls[9]];
             NSDictionary *topPostsYesterdayDict = [batch dictionaryForKey:urls[10]];
             if (topPostsTodayDict && topPostsYesterdayDict) {
                 topPosts = [WPStatsTopPost postsFromTodaysData:topPostsTodayDict yesterdaysData:topPostsYesterdayDict];
             }
             
             WPStatsViewsVisitors *viewsVisitors = [[WPStatsViewsVisitors alloc] init];
             NSDictionary *viewsVisitorsDayDict = [batch dictionaryForKey:urls[11]];
             if (viewsVisitorsDayDict) {
                 [viewsVisitors addViewsVisitorsWithData:viewsVisitorsDayDict unit:StatsViewsVisitorsUnitDay];
             }
             
             NSDictionary *viewsVisitorsWeekDict = [batch dictionaryForKey:urls[12]];
             if (viewsVisitorsWeekDict) {
                 [viewsVisitors addViewsVisitorsWithData:viewsVisitorsWeekDict unit:StatsViewsVisitorsUnitWeek];
             }
             
             NSDictionary *viewsVisitorsMonthDict = [batch dictionaryForKey:urls[13]];
             if (viewsVisitorsMonthDict) {
                 [viewsVisitors addViewsVisitorsWithData:viewsVisitorsMonthDict unit:StatsViewsVisitorsUnitMonth];
             }
             
             // (StatsSummary *summary, NSDictionary *topPosts, NSDictionary *clicks, NSDictionary *countryViews, NSDictionary *referrers, NSDictionary *searchTerms, StatsViewsVisitors *viewsVisitors);
             if (completionHandler) {
                 completionHandler(
                                   statsSummary,
                                   topPosts,
                                   @{StatsResultsToday : clicksToday, StatsResultsYesterday : clicksYesterday},
                                   @{StatsResultsToday : countryViewsToday, StatsResultsYesterday : countryViewsYesterday},
                                   @{StatsResultsToday : referrersToday, StatsResultsYesterday : referrersYesterday},
                                   @{StatsResultsToday : searchTermsToday, StatsResultsYesterday : searchTermsYesterday},
                                   viewsVisitors
                                   );
                 
             }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error with batch stats: %@", error);
        
        if (failureHandler) {
            failureHandler(error);
        }
    }];
}


// For simplicity of implementation (copy & paste), batch is being used here even though its not necessary
- (void)fetchSummaryStatsForTodayWithCompletionHandler:(void (^)(WPStatsSummary *summary))completionHandler failureHandler:(void (^)(NSError *error))failureHandler
{
    NSArray *urls = @[
                      [self urlForSummary],
                      ];
    
    // This needs to eventually be replaced with an instance of WordPressComApi when it's decoupled from Core Data
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", self.oauth2Token]
                     forHTTPHeaderField:@"Authorization"];
    
    [manager GET:[self urlForBatch]
      parameters:@{ @"urls" : urls}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             if (![responseObject isKindOfClass:[NSDictionary class]]) {
                 if (failureHandler) {
                     NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                          code:NSURLErrorBadServerResponse
                                                      userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                     failureHandler(error);
                 }
                 
                 return;
             }
             
             NSDictionary *batch = (NSDictionary *)responseObject;
             
             WPStatsSummary *statsSummary;
             NSDictionary *statsSummaryDict = [batch dictionaryForKey:urls[0]];
             if (statsSummaryDict) {
                 statsSummary = [[WPStatsSummary alloc] initWithData:statsSummaryDict];
             }
             
             if (completionHandler) {
                 completionHandler(statsSummary);
                 
             }
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             DDLogError(@"Error with today summary stats: %@", error);
             
             if (failureHandler) {
                 failureHandler(error);
             }
         }];
}

- (NSString *)urlForBatch
{
    return [NSString stringWithFormat:@"%@/batch", WordPressComApiClientEndpointURL];
}

- (NSString *)urlForSummary
{
    return self.statsPathPrefix;
}

- (NSString *)urlForClicksForDate:(NSString *)date
{
    return [NSString stringWithFormat:@"%@/clicks?date=%@", self.statsPathPrefix, date];
}

- (NSString *)urlForCountryViewsForDate:(NSString *)date
{
    return [NSString stringWithFormat:@"%@/country-views?date=%@", self.statsPathPrefix, date];
}

- (NSString *)urlForReferrerForDate:(NSString *)date
{
    return [NSString stringWithFormat:@"%@/referrers?date=%@", self.statsPathPrefix, date];
}

- (NSString *)urlForSearchTermsForDate:(NSString *)date
{
    return [NSString stringWithFormat:@"%@/search-terms?date=%@", self.statsPathPrefix, date];
}

- (NSString *)urlForTopPostsForDate:(NSString *)date
{
    return [NSString stringWithFormat:@"%@/top-posts?date=%@", self.statsPathPrefix, date];
}

- (NSString *)urlForViewsVisitorsForUnit:(NSString *)unit
{
    NSInteger quantity = IS_IPAD ? 12 : 7;
    return [NSString stringWithFormat:@"%@/visits?unit=%@&quantity=%@", self.statsPathPrefix, unit, @(quantity)];
}

@end
