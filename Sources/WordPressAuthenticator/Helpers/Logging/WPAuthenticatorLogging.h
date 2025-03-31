#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WordPressLoggingDelegate;

FOUNDATION_EXTERN id<WordPressLoggingDelegate> _Nullable WPAuthenticatorGetLoggingDelegate(void);
FOUNDATION_EXTERN void WPAuthenticatorSetLoggingDelegate(id<WordPressLoggingDelegate> _Nullable logger);

FOUNDATION_EXTERN void WPAuthenticatorLogError(NSString *str, ...)     NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPAuthenticatorLogWarning(NSString *str, ...)   NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPAuthenticatorLogInfo(NSString *str, ...)      NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPAuthenticatorLogDebug(NSString *str, ...)     NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPAuthenticatorLogVerbose(NSString *str, ...)   NS_FORMAT_FUNCTION(1, 2);

FOUNDATION_EXTERN void WPAuthenticatorLogvError(NSString *str, va_list args)     NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPAuthenticatorLogvWarning(NSString *str, va_list args)   NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPAuthenticatorLogvInfo(NSString *str, va_list args)      NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPAuthenticatorLogvDebug(NSString *str, va_list args)     NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPAuthenticatorLogvVerbose(NSString *str, va_list args)   NS_FORMAT_FUNCTION(1, 0);

NS_ASSUME_NONNULL_END
