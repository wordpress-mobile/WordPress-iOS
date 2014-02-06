//
//  SPSimperiumLogger.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 10/31/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPSimperiumLogger.h"



#pragma mark ====================================================================================
#pragma mark SPRemoteLogger
#pragma mark ====================================================================================

@implementation SPSimperiumLogger

+ (instancetype)sharedInstance {
	static SPSimperiumLogger* logger;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		logger = [[[self class] alloc] init];
	});
	
	return logger;
}

- (void)logMessage:(DDLogMessage *)logMessage {
    NSString *message = (formatter) ? [formatter formatLogMessage:logMessage] : logMessage->logMsg;
	
    if (message != nil && self.delegate != nil) {
		[self.delegate handleLogMessage:message];
	}
}

@end
