#import "ReachabilityFacade.h"
#import "ReachabilityUtils.h"

@implementation ReachabilityFacade

- (BOOL)isInternetReachable
{
    return [ReachabilityUtils isInternetReachable];
}

- (void)showAlertNoInternetConnection
{
    [ReachabilityUtils showAlertNoInternetConnection];
}

- (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)())retryBlock
{
    [ReachabilityUtils showAlertNoInternetConnectionWithRetryBlock:retryBlock];
}

@end
