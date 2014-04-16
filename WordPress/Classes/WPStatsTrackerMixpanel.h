#import <Foundation/Foundation.h>
#import "WPAnalytics.h"

@interface WPStatsTrackerMixpanel : NSObject <WPAnalyticsTracker> {
    NSMutableDictionary *_aggregatedStatProperties;
}

@end
