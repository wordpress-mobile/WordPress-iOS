#import <Foundation/Foundation.h>
#import "WPStats.h"

@interface WPStatsMixpanelClient : NSObject <WPStatsClient> {
    NSMutableDictionary *_aggregatedStatProperties;
}

@end
