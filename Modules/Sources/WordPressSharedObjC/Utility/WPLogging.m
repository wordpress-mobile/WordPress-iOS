#import "WPLogging.h"
#import "WordPressLoggingDelegate.h"

static id<WordPressLoggingDelegate> wordPressLogger = nil;

id<WordPressLoggingDelegate> _Nullable WPGetLoggingDelegate(void)
{
    return wordPressLogger;
}

void WPSetLoggingDelegate(id<WordPressLoggingDelegate> _Nullable logger)
{
    wordPressLogger = logger;
}

#define WPLogv(logFunc) \
    ({ \
        id<WordPressLoggingDelegate> logger = WPGetLoggingDelegate(); \
        if (logger == NULL) { \
            NSLog(@"Warning: please call `WPSetLoggingDelegate` to set a error logger."); \
            return; \
        } \
        if (![logger respondsToSelector:@selector(logFunc)]) { \
            NSLog(@"Warning: %@ does not implement " #logFunc, logger); \
            return; \
        } \
        /* Originally `performSelector:withObject:` was used to call the logging function, but for unknown reason */ \
        /* it causes a crash on `objc_retain`. So I have to switch to this strange "syntax" to call the logging function directly. */ \
        [logger logFunc [[NSString alloc] initWithFormat:str arguments:args]]; \
    })

#define WPLog(logFunc) \
    ({ \
        va_list args; \
        va_start(args, str); \
        WPLogv(logFunc); \
        va_end(args); \
    })

void WPLogError(NSString *str, ...)   { WPLog(logError:); }
void WPLogWarning(NSString *str, ...) { WPLog(logWarning:); }
void WPLogInfo(NSString *str, ...)    { WPLog(logInfo:); }
void WPLogDebug(NSString *str, ...)   { WPLog(logDebug:); }
void WPLogVerbose(NSString *str, ...) { WPLog(logVerbose:); }

void WPLogvError(NSString *str, va_list args)     { WPLogv(logError:); }
void WPLogvWarning(NSString *str, va_list args)   { WPLogv(logWarning:); }
void WPLogvInfo(NSString *str, va_list args)      { WPLogv(logInfo:); }
void WPLogvDebug(NSString *str, va_list args)     { WPLogv(logDebug:); }
void WPLogvVerbose(NSString *str, va_list args)   { WPLogv(logVerbose:); }
