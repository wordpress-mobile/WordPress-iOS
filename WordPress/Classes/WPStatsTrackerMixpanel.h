#import <Foundation/Foundation.h>
#import "WPStats.h"

@interface WPStatsTrackerMixpanel : NSObject <WPStatsTracker> {
    NSMutableDictionary *_aggregatedStatProperties;
}

@end
