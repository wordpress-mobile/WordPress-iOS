#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WordPressLoggingDelegate <NSObject>

- (void)logError:(NSString *)str;
- (void)logWarning:(NSString *)str;
- (void)logInfo:(NSString *)str;
- (void)logDebug:(NSString *)str;
- (void)logVerbose:(NSString *)str;

@end

NS_ASSUME_NONNULL_END
