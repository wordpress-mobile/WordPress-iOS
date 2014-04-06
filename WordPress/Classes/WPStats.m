#import "WPStats.h"
#import "WPStatsMixpanelClient.h"
@implementation WPStats

+ (id<WPStatsClient>)sharedInstance
{
    static id<WPStatsClient> sharedInstance = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[WPStatsMixpanelClient alloc] init];
    });
    
    return sharedInstance;
}

+ (void)track:(WPStat)stat
{
    [[self sharedInstance] track:stat];
}

@end
