#import "WPStatsServiceRemote.h"
#import "NSObject+SafeExpectations.h"
#import "NSDictionary+SafeExpectations.h"
#import "StatsGroup.h"
#import "StatsViewByCountry.h"
#import "StatsTitleCountItem.h"
#import "StatsTopPost.h"

@interface WPStatsServiceRemote ()

@property (nonatomic, strong) WordPressComApi *api;
@property (nonatomic, strong) NSNumber *siteId;
@property (nonatomic, copy) NSString *statsPathPrefix;

@end

@implementation WPStatsServiceRemote {

}

- (instancetype)initWithRemoteApi:(WordPressComApi *)api andSiteId:(NSNumber *)siteId
{
    self = [super init];
    if (self) {
        _api = api;
        _siteId = siteId;
        _statsPathPrefix = [NSString stringWithFormat:@"/sites/%@/stats", _siteId];
    }

    return self;
}

- (void)fetchStatsForTodayDate:(NSDate *)today andYesterdayDate:(NSDate *)yesterday withCompletionHandler:(StatsCompletion)completionHandler failureHandler:(void (^)(NSError *error))failureHandler
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd";

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

    [self.api GET:@"batch"
       parameters:@{ @"urls" : urls}
          success:^void (AFHTTPRequestOperation *operation, id responseObject)
     {
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
         
         StatsSummary *statsSummary;
         NSDictionary *statsSummaryDict = [batch dictionaryForKey:urls[0]];
         if (statsSummaryDict) {
             statsSummary = [[StatsSummary alloc] initWithData:statsSummaryDict];
         }
         
         NSArray *clicksToday = @[];
         NSDictionary *clicksTodayDict = [batch dictionaryForKey:urls[1]];
         if (clicksTodayDict) {
             clicksToday = [StatsGroup groupsFromData:clicksTodayDict[@"clicks"]];
         }
         
         NSArray *clicksYesterday = @[];
         NSDictionary *clicksYesterdayDict = [batch dictionaryForKey:urls[2]];
         if (clicksYesterdayDict) {
             clicksYesterday = [StatsGroup groupsFromData:clicksYesterdayDict[@"clicks"]];
         }
         
         NSArray *countryViewsToday = @[];
         NSDictionary *countryViewsTodayDict = [batch dictionaryForKey:urls[3]];
         if (countryViewsTodayDict) {
             countryViewsToday = [StatsViewByCountry viewByCountryFromData:countryViewsTodayDict];
         }
         
         NSArray *countryViewsYesterday = @[];
         NSDictionary *countryViewsYesterdayDict = [batch dictionaryForKey:urls[4]];
         if (countryViewsYesterdayDict) {
             countryViewsYesterday = [StatsViewByCountry viewByCountryFromData:countryViewsYesterdayDict];
         }
         
         NSArray *referrersToday = @[];
         NSDictionary *referrersTodayDict = [batch dictionaryForKey:urls[5]];
         if (referrersTodayDict) {
             referrersToday = [StatsGroup groupsFromData:referrersTodayDict[@"referrers"]];
         }
         
         NSArray *referrersYesterday = @[];
         NSDictionary *referrersYesterdayDict = [batch dictionaryForKey:urls[6]];
         if (referrersYesterdayDict) {
             referrersYesterday = [StatsGroup groupsFromData:referrersYesterdayDict[@"referrers"]];
         }
         
         NSArray *searchTermsToday = @[];
         NSDictionary *searchTermsTodayDict = [batch dictionaryForKey:urls[7]];
         if (searchTermsTodayDict) {
             searchTermsToday = [StatsTitleCountItem titleCountItemsFromData:searchTermsTodayDict[@"search-terms"]];
         }
         
         NSArray *searchTermsYesterday = @[];
         NSDictionary *searchTermsYesterdayDict = [batch dictionaryForKey:urls[8]];
         if (searchTermsYesterdayDict) {
             searchTermsYesterday = [StatsTitleCountItem titleCountItemsFromData:searchTermsYesterdayDict[@"search-terms"]];
         }
         
         NSDictionary *topPosts = @{};
         NSDictionary *topPostsTodayDict = [batch dictionaryForKey:urls[9]];
         NSDictionary *topPostsYesterdayDict = [batch dictionaryForKey:urls[10]];
         if (topPostsTodayDict && topPostsYesterdayDict) {
             topPosts = [StatsTopPost postsFromTodaysData:topPostsTodayDict yesterdaysData:topPostsYesterdayDict];
         }
         
         StatsViewsVisitors *viewsVisitors = [[StatsViewsVisitors alloc] init];
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
     }
          failure:^void (AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Error: %@", error);
         
         if (failureHandler) {
             failureHandler(error);
         }
     }
     ];

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
    return [NSString stringWithFormat:@"%@/visits?unit=%@&quantity=%d", self.statsPathPrefix, unit, quantity];
}

@end