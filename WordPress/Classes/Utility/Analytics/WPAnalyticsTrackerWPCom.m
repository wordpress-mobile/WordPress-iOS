#import "WPAnalyticsTrackerWPCom.h"
#import "WordPressAppDelegate.h"
#import "Constants.h"

@implementation WPAnalyticsTrackerWPCom

- (void)track:(WPAnalyticsStat)stat
{
    [self track:stat withProperties:nil];
}

- (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    switch (stat) {
        case WPAnalyticsStatReaderLoadedFreshlyPressed:
            [self pingWPComStatsEndpoint:@"freshly"];
            break;
        case WPAnalyticsStatReaderOpenedArticle:
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
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL]];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
    [conn start];
}

@end

