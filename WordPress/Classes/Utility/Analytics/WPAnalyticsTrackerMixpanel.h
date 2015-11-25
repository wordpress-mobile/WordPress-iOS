#import <Foundation/Foundation.h>
#import <WordPressComAnalytics/WPAnalytics.h>

@class MixpanelProxy;
@interface WPAnalyticsTrackerMixpanel : NSObject <WPAnalyticsTracker> {
    NSMutableDictionary *_aggregatedStatProperties;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context;
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context mixpanelProxy:(MixpanelProxy *)mixpanelProxy;

@end
