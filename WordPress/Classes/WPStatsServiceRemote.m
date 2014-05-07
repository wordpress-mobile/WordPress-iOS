#import "WPStatsServiceRemote.h"


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

- (void)fetchStatsForSiteId:(NSNumber *)siteId withCompletionHandler:(StatsCompletion)completionHandler failureHandler:(void (^)(NSError *error))failureHandler
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd";

    NSDate *today = [NSDate date];
    NSString *todayString = [formatter stringFromDate:today];

    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:-1];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *yesterday = [calendar dateByAddingComponents:dateComponents toDate:today options:NSCalendarUnitDay];
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

    [self.api getPath:@"batch"
           parameters:@{ @"urls" : urls}
              success:^void (AFHTTPRequestOperation *operation, id responseObject)
            {
                NSLog(@"Response: %@", responseObject);

            }
              failure:^void (AFHTTPRequestOperation *operation, NSError *error)
            {
                NSLog(@"Error: %@", error);

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