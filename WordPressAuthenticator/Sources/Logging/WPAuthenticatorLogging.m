#import "WPAuthenticatorLogging.h"

@import WordPressShared;

static id<WordPressLoggingDelegate> wordPressAuthenticatorLogger = nil;

id<WordPressLoggingDelegate> _Nullable WPAuthenticatorGetLoggingDelegate(void)
{
    return wordPressAuthenticatorLogger;
}

void WPAuthenticatorSetLoggingDelegate(id<WordPressLoggingDelegate> _Nullable logger)
{
    wordPressAuthenticatorLogger = logger;
}

#define WPAuthenticatorLogv(logFunc) \
    ({ \
        id<WordPressLoggingDelegate> logger = WPAuthenticatorGetLoggingDelegate(); \
        if (logger == NULL) { \
            NSLog(@"[WordPressAuthenticator] Warning: please call `WPAuthenticatorSetLoggingDelegate` to set a error logger."); \
            return; \
        } \
        if (![logger respondsToSelector:@selector(logFunc)]) { \
            NSLog(@"[WordPressAuthenticator] Warning: %@ does not implement " #logFunc, logger); \
            return; \
        } \
        /* Originally `performSelector:withObject:` was used to call the logging function, but for unknown reason */ \
        /* it causes a crash on `objc_retain`. So I have to switch to this strange "syntax" to call the logging function directly. */ \
        [logger logFunc [[NSString alloc] initWithFormat:str arguments:args]]; \
    })

#define WPAuthenticatorLog(logFunc) \
    ({ \
        va_list args; \
        va_start(args, str); \
        WPAuthenticatorLogv(logFunc); \
        va_end(args); \
    })

void WPAuthenticatorLogError(NSString *str, ...)   { WPAuthenticatorLog(logError:); }
void WPAuthenticatorLogWarning(NSString *str, ...) { WPAuthenticatorLog(logWarning:); }
void WPAuthenticatorLogInfo(NSString *str, ...)    { WPAuthenticatorLog(logInfo:); }
void WPAuthenticatorLogDebug(NSString *str, ...)   { WPAuthenticatorLog(logDebug:); }
void WPAuthenticatorLogVerbose(NSString *str, ...) { WPAuthenticatorLog(logVerbose:); }

void WPAuthenticatorLogvError(NSString *str, va_list args)     { WPAuthenticatorLogv(logError:); }
void WPAuthenticatorLogvWarning(NSString *str, va_list args)   { WPAuthenticatorLogv(logWarning:); }
void WPAuthenticatorLogvInfo(NSString *str, va_list args)      { WPAuthenticatorLogv(logInfo:); }
void WPAuthenticatorLogvDebug(NSString *str, va_list args)     { WPAuthenticatorLogv(logDebug:); }
void WPAuthenticatorLogvVerbose(NSString *str, va_list args)   { WPAuthenticatorLogv(logVerbose:); }
