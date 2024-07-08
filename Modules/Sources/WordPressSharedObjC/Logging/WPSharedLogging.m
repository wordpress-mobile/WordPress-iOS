#import "WPSharedLogging.h"

static id<WordPressLoggingDelegate> wordPressSharedLogger = nil;

id<WordPressLoggingDelegate> _Nullable WPSharedGetLoggingDelegate(void)
{
    return wordPressSharedLogger;
}

void WPSharedSetLoggingDelegate(id<WordPressLoggingDelegate> _Nullable logger)
{
    wordPressSharedLogger = logger;
}

#define WPSharedLogv(logFunc) \
    ({ \
        id<WordPressLoggingDelegate> logger = WPSharedGetLoggingDelegate(); \
        if (logger == NULL) { \
            NSLog(@"[WordPress-Shared] Warning: please call `WPSharedSetLoggingDelegate` to set a error logger."); \
            return; \
        } \
        if (![logger respondsToSelector:@selector(logFunc)]) { \
            NSLog(@"[WordPress-Shared] Warning: %@ does not implement " #logFunc, logger); \
            return; \
        } \
        /* Originally `performSelector:withObject:` was used to call the logging function, but for unknown reason */ \
        /* it causes a crash on `objc_retain`. So I have to switch to this strange "syntax" to call the logging function directly. */ \
        [logger logFunc [[NSString alloc] initWithFormat:str arguments:args]]; \
    })

#define WPSharedLog(logFunc) \
    ({ \
        va_list args; \
        va_start(args, str); \
        WPSharedLogv(logFunc); \
        va_end(args); \
    })

void WPSharedLogError(NSString *str, ...)   { WPSharedLog(logError:); }
void WPSharedLogWarning(NSString *str, ...) { WPSharedLog(logWarning:); }
void WPSharedLogInfo(NSString *str, ...)    { WPSharedLog(logInfo:); }
void WPSharedLogDebug(NSString *str, ...)   { WPSharedLog(logDebug:); }
void WPSharedLogVerbose(NSString *str, ...) { WPSharedLog(logVerbose:); }

void WPSharedLogvError(NSString *str, va_list args)     { WPSharedLogv(logError:); }
void WPSharedLogvWarning(NSString *str, va_list args)   { WPSharedLogv(logWarning:); }
void WPSharedLogvInfo(NSString *str, va_list args)      { WPSharedLogv(logInfo:); }
void WPSharedLogvDebug(NSString *str, va_list args)     { WPSharedLogv(logDebug:); }
void WPSharedLogvVerbose(NSString *str, va_list args)   { WPSharedLogv(logVerbose:); }
