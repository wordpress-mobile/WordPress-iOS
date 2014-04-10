#import "WPStats.h"

@implementation WPStats

+ (NSMutableArray *)sharedInstances
{
    static NSMutableArray *sharedInstances = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstances = [[NSMutableArray alloc] init];
    });
    
    return sharedInstances;
}

+ (void)registerClient:(id<WPStatsClient>)client
{
    NSParameterAssert(client != nil);
    [[self sharedInstances] addObject:client];
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
