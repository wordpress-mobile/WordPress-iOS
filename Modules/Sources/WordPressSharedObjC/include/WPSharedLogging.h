#import <Foundation/Foundation.h>
#import "WordPressLoggingDelegate.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN id<WordPressLoggingDelegate> _Nullable WPSharedGetLoggingDelegate(void);
FOUNDATION_EXTERN void WPSharedSetLoggingDelegate(id<WordPressLoggingDelegate> _Nullable logger);

FOUNDATION_EXTERN void WPSharedLogError(NSString *str, ...)     NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPSharedLogWarning(NSString *str, ...)   NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPSharedLogInfo(NSString *str, ...)      NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPSharedLogDebug(NSString *str, ...)     NS_FORMAT_FUNCTION(1, 2);
FOUNDATION_EXTERN void WPSharedLogVerbose(NSString *str, ...)   NS_FORMAT_FUNCTION(1, 2);

FOUNDATION_EXTERN void WPSharedLogvError(NSString *str, va_list args)     NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPSharedLogvWarning(NSString *str, va_list args)   NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPSharedLogvInfo(NSString *str, va_list args)      NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPSharedLogvDebug(NSString *str, va_list args)     NS_FORMAT_FUNCTION(1, 0);
FOUNDATION_EXTERN void WPSharedLogvVerbose(NSString *str, va_list args)   NS_FORMAT_FUNCTION(1, 0);

NS_ASSUME_NONNULL_END
