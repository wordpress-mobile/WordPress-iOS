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

+ (void)track:(WPStat)stat withProperties:(NSDictionary *)properties
{
    NSParameterAssert(properties != nil);
    [[self sharedInstance] track:stat withProperties:properties];
}

+ (void)endSession
{
    [[self sharedInstance] endSession];
}

@end
