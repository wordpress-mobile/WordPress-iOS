#import <Foundation/Foundation.h>
#import "WPAnalytics.h"

@interface WPAnalyticsTrackerMixpanel : NSObject <WPAnalyticsTracker>

+ (void)resetEmailRetrievalCheck;

@end
