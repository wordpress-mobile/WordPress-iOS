//
//  CrashlyticsLogger.m
//
//  Created by Simons, Mike on 5/16/13.
//  Copyright (c) 2013 TechSmith. All rights reserved.
//

#import "CrashlyticsLogger.h"

OBJC_EXTERN void CLSLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

@implementation CrashlyticsLogger

-(void) logMessage:(DDLogMessage *)logMessage
{
    NSString *logMsg = logMessage->logMsg;
    
    if (formatter)
    {
        logMsg = [formatter formatLogMessage:logMessage];
    }
    
    if (logMsg)
    {
        CLSLog(@"%@",logMsg);
    }
}


+(CrashlyticsLogger*) sharedInstance
{
    static dispatch_once_t pred = 0;
    static CrashlyticsLogger *_sharedInstance = nil;
    
    dispatch_once(&pred, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

@end
