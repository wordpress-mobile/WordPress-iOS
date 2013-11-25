//
//  CrashlyticsLogger.m
//
//  Created by Simons, Mike on 5/16/13.
//  Copyright (c) 2013 TechSmith. All rights reserved.
//


#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject; \


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
   DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
   
      return [[CrashlyticsLogger alloc] init];
   });
}

@end
