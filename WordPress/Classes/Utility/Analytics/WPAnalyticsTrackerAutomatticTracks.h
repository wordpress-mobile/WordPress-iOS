#import <Foundation/Foundation.h>
#import <WordPressShared/WPAnalytics.h>

@interface TracksEventPair: NSObject
@property (nonnull, nonatomic, copy) NSString *eventName;
@property (nullable, nonatomic, strong) NSDictionary *properties;
@end

@interface WPAnalyticsTrackerAutomatticTracks: NSObject<WPAnalyticsTracker>

+ (nonnull NSString *)eventNameForStat:(WPAnalyticsStat)stat;
+ (nonnull TracksEventPair *)eventPairForStat:(WPAnalyticsStat)stat;

@end
