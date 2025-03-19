#import <Foundation/Foundation.h>
@import WordPressSharedObjC;

@interface WPAnalyticsTrackerAutomatticTracks : NSObject<WPAnalyticsTracker>

+ (NSString *)eventNameForStat:(WPAnalyticsStat)stat;

- (instancetype)initWithEventNamePrefix:(NSString *)eventNamePrefix platform:(NSString *)platform;

@end
