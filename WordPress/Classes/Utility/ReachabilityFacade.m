#import "ReachabilityFacade.h"
#import "ReachabilityUtils.h"

@implementation ReachabilityFacade

- (BOOL)isInternetReachable
{
    return [ReachabilityUtils isInternetReachable];
}

- (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)(void))retryBlock
{
    [ReachabilityUtils showAlertNoInternetConnectionWithRetryBlock:retryBlock];
}

@end
