#import <Foundation/Foundation.h>

@protocol ReachabilityFacade <NSObject>

- (BOOL)isInternetReachable;
- (void)showAlertNoInternetConnection;
- (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)())retryBlock;

@end

@interface ReachabilityFacade : NSObject <ReachabilityFacade>

@end
