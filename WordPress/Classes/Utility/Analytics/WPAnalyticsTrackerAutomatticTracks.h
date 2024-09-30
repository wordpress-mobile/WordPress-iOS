#import <Foundation/Foundation.h>
@import WordPressSharedObjC;

@interface WPAnalyticsTrackerAutomatticTracks : NSObject<WPAnalyticsTracker>

+ (NSString *)eventNameForStat:(WPAnalyticsStat)stat;

@end
