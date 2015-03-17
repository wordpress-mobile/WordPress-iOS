#import <Foundation/Foundation.h>

@protocol ReachabilityService <NSObject>

- (BOOL)isInternetReachable;
- (void)showAlertNoInternetConnection;
- (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)())retryBlock;

@end

@interface ReachabilityService : NSObject <ReachabilityService>

@end
