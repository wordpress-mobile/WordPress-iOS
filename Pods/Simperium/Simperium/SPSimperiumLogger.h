//
//  SPSimperiumLogger.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 10/31/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "DDLog.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

NS_ENUM(NSInteger, SPRemoteLogLevels) {
	SPRemoteLogLevelsOff		= 0,
	SPRemoteLogLevelsRegular	= 1,
	SPRemoteLogLevelsVerbose	= 2
};


#pragma mark ====================================================================================
#pragma mark SPSimperiumLoggerDelegate
#pragma mark ====================================================================================

@protocol SPSimperiumLoggerDelegate <NSObject>
- (void)handleLogMessage:(NSString*)logMessage;
@end


#pragma mark ====================================================================================
#pragma mark SPSimperiumLogger
#pragma mark ====================================================================================

@interface SPSimperiumLogger : DDAbstractLogger <DDLogger>

@property (nonatomic, weak, readwrite) id<SPSimperiumLoggerDelegate> delegate;

+ (instancetype)sharedInstance;

@end
