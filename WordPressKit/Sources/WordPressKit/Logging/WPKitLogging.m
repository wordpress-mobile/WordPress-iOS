#import "WPKitLogging.h"

static id<WordPressLoggingDelegate> wordPressKitLogger = nil;

id<WordPressLoggingDelegate> _Nullable WPKitGetLoggingDelegate(void)
{
    return wordPressKitLogger;
}

void WPKitSetLoggingDelegate(id<WordPressLoggingDelegate> _Nullable logger)
{
    wordPressKitLogger = logger;
}

#define WPKitLogv(logFunc) \
    ({ \
        id<WordPressLoggingDelegate> logger = WPKitGetLoggingDelegate(); \
        if (logger == NULL) { \
            NSLog(@"[WordPressKit] Warning: please call `WPKitSetLoggingDelegate` to set a error logger."); \
            return; \
        } \
        if (![logger respondsToSelector:@selector(logFunc)]) { \
            NSLog(@"[WordPressKit] Warning: %@ does not implement " #logFunc, logger); \
            return; \
        } \
        /* Originally `performSelector:withObject:` was used to call the logging function, but for unknown reason */ \
        /* it causes a crash on `objc_retain`. So I have to switch to this strange "syntax" to call the logging function directly. */ \
        [logger logFunc [[NSString alloc] initWithFormat:str arguments:args]]; \
    })

#define WPKitLog(logFunc) \
    ({ \
        va_list args; \
        va_start(args, str); \
        WPKitLogv(logFunc); \
        va_end(args); \
    })

void WPKitLogError(NSString *str, ...)   { WPKitLog(logError:); }
void WPKitLogWarning(NSString *str, ...) { WPKitLog(logWarning:); }
void WPKitLogInfo(NSString *str, ...)    { WPKitLog(logInfo:); }
void WPKitLogDebug(NSString *str, ...)   { WPKitLog(logDebug:); }
void WPKitLogVerbose(NSString *str, ...) { WPKitLog(logVerbose:); }

void WPKitLogvError(NSString *str, va_list args)     { WPKitLogv(logError:); }
void WPKitLogvWarning(NSString *str, va_list args)   { WPKitLogv(logWarning:); }
void WPKitLogvInfo(NSString *str, va_list args)      { WPKitLogv(logInfo:); }
void WPKitLogvDebug(NSString *str, va_list args)     { WPKitLogv(logDebug:); }
void WPKitLogvVerbose(NSString *str, va_list args)   { WPKitLogv(logVerbose:); }
