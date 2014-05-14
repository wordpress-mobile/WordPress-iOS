#import <Foundation/Foundation.h>

@interface ReachabilityUtils : NSObject

+ (BOOL)isInternetReachable;

+ (void)showAlertNoInternetConnection;

+ (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)())retryBlock;

@end
