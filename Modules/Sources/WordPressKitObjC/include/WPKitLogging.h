#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WordPressKitLoggingDelegate <NSObject>

- (void)logError:(NSString *)str;
- (void)logWarning:(NSString *)str;
- (void)logInfo:(NSString *)str;
- (void)logDebug:(NSString *)str;
- (void)logVerbose:(NSString *)str;

@end

FOUNDATION_EXTERN id<WordPressKitLoggingDelegate> _Nullable WPKitGetLoggingDelegate(void);
FOUNDATION_EXTERN void WPKitSetLoggingDelegate(id<WordPressKitLoggingDelegate> _Nullable logger);

FOUNDATION_EXTERN void WPKitLogError(NSString *str, ...)     NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPKitLogWarning(NSString *str, ...)   NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPKitLogInfo(NSString *str, ...)      NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPKitLogDebug(NSString *str, ...)     NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPKitLogVerbose(NSString *str, ...)   NS_FORMAT_FUNCTION(1, 2);

FOUNDATION_EXTERN void WPKitLogvError(NSString *str, va_list args)     NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPKitLogvWarning(NSString *str, va_list args)   NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPKitLogvInfo(NSString *str, va_list args)      NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPKitLogvDebug(NSString *str, va_list args)     NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPKitLogvVerbose(NSString *str, va_list args)   NS_FORMAT_FUNCTION(1, 0);

NS_ASSUME_NONNULL_END
