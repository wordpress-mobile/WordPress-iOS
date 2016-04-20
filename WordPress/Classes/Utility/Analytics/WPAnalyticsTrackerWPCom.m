#import "WPAnalyticsTrackerWPCom.h"
#import "WordPressAppDelegate.h"
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

- (void)pingWPComStatsEndpoint:(NSString *)statName
{
    int x = arc4random();
    NSString *statsURL = [NSString stringWithFormat:@"%@%@%@%@%d" , WPMobileReaderURL, @"&template=stats&stats_name=", statName, @"&rnd=", x];
    NSString *userAgent = [[WordPressAppDelegate sharedInstance].userAgent wordPressUserAgent];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL]];
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}

@end
