#import "WPAnalytics.h"

@implementation WPAnalytics

+ (NSMutableArray *)trackers
{
    static NSMutableArray *trackers = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        trackers = [[NSMutableArray alloc] init];
    });
    
    return trackers;
}

+ (void)registerTracker:(id<WPAnalyticsTracker>)tracker
{
    NSParameterAssert(tracker != nil);
    [[self trackers] addObject:tracker];
}

+ (void)track:(WPAnalyticsStat)stat
{
    for (id<WPAnalyticsTracker> tracker in [self trackers]) {
        [tracker track:stat];
    }
}

+ (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    NSParameterAssert(properties != nil);
    for (id<WPAnalyticsTracker> tracker in [self trackers]) {
        [tracker track:stat withProperties:properties];
    }
}

+ (void)beginSession
{
    for (id<WPAnalyticsTracker> tracker in [self trackers]) {
        if ([tracker respondsToSelector:@selector(beginSession)]) {
            [tracker beginSession];
        }
    }
}

+ (void)endSession
{
    for (id<WPAnalyticsTracker> tracker in [self trackers]) {
        if ([tracker respondsToSelector:@selector(endSession)]) {
            [tracker endSession];
        }
    }
}

@end
