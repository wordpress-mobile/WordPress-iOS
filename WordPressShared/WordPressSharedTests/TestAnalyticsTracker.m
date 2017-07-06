#import "TestAnalyticsTracker.h"

@implementation TestAnalyticsTracker

- (void)track:(WPAnalyticsStat)stat
{
    // No-op
}

- (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    // No-op
}

- (void)beginSession
{
    // No-op
}

- (void)endSession
{
    // No-op
}

- (void)refreshMetadata
{
    // No-op
}

@end
