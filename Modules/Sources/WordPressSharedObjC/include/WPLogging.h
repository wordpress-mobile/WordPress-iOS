#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WordPressLoggingDelegate;

FOUNDATION_EXTERN id<WordPressLoggingDelegate> _Nullable WPGetLoggingDelegate(void);
FOUNDATION_EXTERN void WPSetLoggingDelegate(id<WordPressLoggingDelegate> _Nullable logger);

FOUNDATION_EXTERN void WPLogError(NSString *str, ...)     NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPLogWarning(NSString *str, ...)   NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPLogInfo(NSString *str, ...)      NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPLogDebug(NSString *str, ...)     NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPLogVerbose(NSString *str, ...)   NS_FORMAT_FUNCTION(1, 2);

FOUNDATION_EXTERN void WPLogvError(NSString *str, va_list args)     NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPLogvWarning(NSString *str, va_list args)   NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPLogvInfo(NSString *str, va_list args)      NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPLogvDebug(NSString *str, va_list args)     NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPLogvVerbose(NSString *str, va_list args)   NS_FORMAT_FUNCTION(1, 0);

NS_ASSUME_NONNULL_END
