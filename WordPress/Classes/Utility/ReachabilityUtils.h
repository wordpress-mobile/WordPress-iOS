#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReachabilityUtils : NSObject

+ (BOOL)isInternetReachable;

+ (NSString *)noConnectionMessage;

@end

NS_ASSUME_NONNULL_END
