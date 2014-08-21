#import <Foundation/Foundation.h>
#import "WPAnalytics.h"

@interface TestAnalyticsTracker : NSObject<WPAnalyticsTracker>

- (void)track:(WPAnalyticsStat)stat;
- (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties;

- (void)beginSession;
- (void)endSession;
- (void)refreshMetadata;

@end
