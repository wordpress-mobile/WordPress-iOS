#import <Foundation/Foundation.h>

@import WordPressShared;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN id<WordPressLoggingDelegate> _Nullable WPKitGetLoggingDelegate(void);
FOUNDATION_EXTERN void WPKitSetLoggingDelegate(id<WordPressLoggingDelegate> _Nullable logger);

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
