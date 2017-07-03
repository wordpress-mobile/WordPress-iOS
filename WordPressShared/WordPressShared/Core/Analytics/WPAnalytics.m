#import "WPAnalytics.h"

NSString *const WPAnalyticsStatEditorPublishedPostPropertyCategory = @"with_categories";
NSString *const WPAnalyticsStatEditorPublishedPostPropertyPhoto = @"with_photos";
NSString *const WPAnalyticsStatEditorPublishedPostPropertyTag = @"with_tags";
NSString *const WPAnalyticsStatEditorPublishedPostPropertyVideo = @"with_videos";

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

+ (void)clearTrackers
{
    [[self trackers] removeAllObjects];
}

+ (void)beginTimerForStat:(WPAnalyticsStat)stat
{
    for (id<WPAnalyticsTracker> tracker in [self trackers]) {
        if ([tracker respondsToSelector:@selector(beginTimerForStat:)]) {
            [tracker beginTimerForStat:stat];
        }
    }
}

+ (void)endTimerForStat:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    for (id<WPAnalyticsTracker> tracker in [self trackers]) {
        if ([tracker respondsToSelector:@selector(endTimerForStat:withProperties:)]) {
            [tracker endTimerForStat:stat withProperties:properties];
        }
    }
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

+ (void)refreshMetadata
{
    for (id<WPAnalyticsTracker> tracker in [self trackers]) {
        if ([tracker respondsToSelector:@selector(refreshMetadata)]) {
            [tracker refreshMetadata];
        }
    }
}

@end
