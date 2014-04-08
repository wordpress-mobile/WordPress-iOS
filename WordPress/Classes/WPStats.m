#import "WPStats.h"
#import "WPStatsMixpanelClient.h"
#import "WPStatsWPComClient.h"

@implementation WPStats

+ (NSArray *)sharedInstances
{
    static NSArray *sharedInstances = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstances = @[[[WPStatsMixpanelClient alloc] init], [[WPStatsWPComClient alloc] init]];
    });
    
    return sharedInstances;
}

+ (void)track:(WPStat)stat
{
    for (id<WPStatsClient> client in [self sharedInstances]) {
        [client track:stat];
    }
}

+ (void)track:(WPStat)stat withProperties:(NSDictionary *)properties
{
    NSParameterAssert(properties != nil);
    for (id<WPStatsClient> client in [self sharedInstances]) {
        [client track:stat withProperties:properties];
    }
}

+ (void)beginSession
{
    for (id<WPStatsClient> client in [self sharedInstances]) {
        if ([client respondsToSelector:@selector(beginSession)]) {
            [client beginSession];
        }
    }
}

+ (void)endSession
{
    for (id<WPStatsClient> client in [self sharedInstances]) {
        if ([client respondsToSelector:@selector(endSession)]) {
            [client endSession];
        }
    }
}

@end
