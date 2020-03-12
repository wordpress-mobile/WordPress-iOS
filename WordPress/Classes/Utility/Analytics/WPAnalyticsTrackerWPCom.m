#import "WPAnalyticsTrackerWPCom.h"
#import "WPUserAgent.h"
#import "Constants.h"

@implementation WPAnalyticsTrackerWPCom

- (void)track:(WPAnalyticsStat)stat
{
    [self track:stat withProperties:nil];
}

- (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    switch (stat) {
        case WPAnalyticsStatReaderFreshlyPressedLoaded:
            [self pingWPComStatsEndpoint:@"freshly"];
            break;
        case WPAnalyticsStatReaderArticleOpened:
            [self pingWPComStatsEndpoint:@"details_page"];
            break;
        case WPAnalyticsStatReaderAccessed:
            [self pingWPComStatsEndpoint:@"home_page"];
            break;
        default:
            break;
    }
}

- (void)trackString:(NSString *)event
{
    // Only WPAnalyticsStat should be used in this Tracker
}

- (void)trackString:(NSString *)event withProperties:(NSDictionary *)properties
{
    // Only WPAnalyticsStat should be used in this Tracker
}

- (void)pingWPComStatsEndpoint:(NSString *)statName
{
    int x = arc4random();
    NSString *statsURL = [NSString stringWithFormat:@"%@%@%@%@%d" , WPMobileReaderURL, @"&template=stats&stats_name=", statName, @"&rnd=", x];
    NSString *userAgent = [WPUserAgent wordPressUserAgent];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL]];
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}

@end
