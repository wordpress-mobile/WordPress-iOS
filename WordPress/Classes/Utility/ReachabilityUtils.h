#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReachabilityUtils : NSObject

+ (BOOL)isInternetReachable;

+ (void)showAlertNoInternetConnection;

+ (void)showAlertNoInternetConnectionWithRetryBlock:(void (^)(void))retryBlock;

+ (NSString *)noConnectionMessage;

@end

NS_ASSUME_NONNULL_END
