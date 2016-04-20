/*
 Original code from https://github.com/TechSmith/CrashlyticsLumberjack
 */

#import "WPCrashlyticsLogger.h"
@import Crashlytics;

@implementation WPCrashlyticsLogger

-(void) logMessage:(DDLogMessage *)logMessage
{
    NSString *logMsg = logMessage->_message;

    if (_logFormatter)
    {
        logMsg = [_logFormatter formatLogMessage:logMessage];
    }

    if (logMsg)
    {
        CLSLog(@"%@",logMsg);
    }
}


+ (instancetype)sharedInstance
{
    static dispatch_once_t pred = 0;
    static WPCrashlyticsLogger *_sharedInstance = nil;

    dispatch_once(&pred, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

@end
