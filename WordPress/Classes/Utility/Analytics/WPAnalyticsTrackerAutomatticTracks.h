#import <Foundation/Foundation.h>
#import <WordPressShared/WPAnalytics.h>

@interface WPAnalyticsTrackerAutomatticTracks : NSObject<WPAnalyticsTracker>

+ (NSString *)eventNameForStat:(WPAnalyticsStat)stat;

@end
