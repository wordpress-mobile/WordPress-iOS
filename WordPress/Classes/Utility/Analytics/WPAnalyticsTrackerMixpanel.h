#import <Foundation/Foundation.h>
#import "WPAnalytics.h"

@interface WPAnalyticsTrackerMixpanel : NSObject <WPAnalyticsTracker> {
    NSMutableDictionary *_aggregatedStatProperties;
}

+ (void)resetEmailRetrievalCheck;

@end
