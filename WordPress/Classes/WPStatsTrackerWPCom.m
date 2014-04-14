#import "WPStatsTrackerWPCom.h"
#import "WordPressAppDelegate.h"
#import "Constants.h"

@implementation WPStatsTrackerWPCom

- (void)track:(WPStat)stat
{
    [self track:stat withProperties:nil];
}

- (void)track:(WPStat)stat withProperties:(NSDictionary *)properties
{
    switch (stat) {
        case WPStatReaderLoadedFreshlyPressed:
            [self pingWPComStatsEndpoint:@"freshly"];
            break;
        case WPStatReaderOpenedArticle:
            [self pingWPComStatsEndpoint:@"details_page"];
            break;
        case WPStatReaderAccessed:
            [self pingWPComStatsEndpoint:@"home_page"];
            break;
        default:
            break;
    }
}

- (void)pingWPComStatsEndpoint:(NSString *)statName
{
    int x = arc4random();
    NSString *statsURL = [NSString stringWithFormat:@"%@%@%@%@%d" , kMobileReaderURL, @"&template=stats&stats_name=", statName, @"&rnd=", x];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL]];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
    [conn start];
}

@end

