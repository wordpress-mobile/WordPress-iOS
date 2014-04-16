#import <Foundation/Foundation.h>
#import "WPAnalytics.h"

@interface WPStatsTrackerMixpanel : NSObject <WPStatsTracker> {
    NSMutableDictionary *_aggregatedStatProperties;
}

@end
