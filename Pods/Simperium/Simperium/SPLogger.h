//
//  SPLogger.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 02/13/14.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

typedef NS_ENUM(NSInteger, SPLogFlags) {
	SPLogFlagsError				= (1 << 0),
	SPLogFlagsWarn				= (1 << 1),
	SPLogFlagsInfo				= (1 << 2),
	SPLogFlagsVerbose			= (1 << 3)
};

typedef NS_ENUM(NSInteger, SPLogLevels) {
	SPLogLevelsOff				= 0,
	SPLogLevelsError			= SPLogFlagsError,
	SPLogLevelsWarn				= SPLogFlagsError | SPLogFlagsWarn,
	SPLogLevelsInfo				= SPLogFlagsError | SPLogFlagsWarn | SPLogFlagsInfo,
	SPLogLevelsVerbose			= SPLogFlagsError | SPLogFlagsWarn | SPLogFlagsInfo | SPLogFlagsVerbose
};


#pragma mark ====================================================================================
#pragma mark "Private": Direct usage is not recommended
#pragma mark ====================================================================================

#define LOG_ME_MAYBE(lvl, flg, frmt, ...)	do { if(lvl & flg || [[SPLogger sharedInstance] sharedLogLevel] & flg)					\
												[[SPLogger sharedInstance] logWithLevel:lvl flag:flg format:(frmt), ##__VA_ARGS__];	\
											} while(0)


#pragma mark ====================================================================================
#pragma mark Loggin Macros
#pragma mark ====================================================================================

#define SPLogError(frmt, ...)				LOG_ME_MAYBE(logLevel, SPLogFlagsError,   frmt, ##__VA_ARGS__)
#define SPLogWarn(frmt, ...)				LOG_ME_MAYBE(logLevel, SPLogFlagsWarn,    frmt, ##__VA_ARGS__)
#define SPLogInfo(frmt, ...)				LOG_ME_MAYBE(logLevel, SPLogFlagsInfo,    frmt, ##__VA_ARGS__)
#define SPLogVerbose(frmt, ...)				LOG_ME_MAYBE(logLevel, SPLogFlagsVerbose, frmt, ##__VA_ARGS__)
#define SPLogOnError(error)					if(error != nil && [error isKindOfClass:[NSError class]]) do { \
												SPLogError(@"%@ error while executing '%@': %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);  \
											} while (0)


#pragma mark ====================================================================================
#pragma mark SPLoggerDelegate
#pragma mark ====================================================================================

@protocol SPLoggerDelegate <NSObject>
- (void)handleLogMessage:(NSString*)logMessage;
@end


#pragma mark ====================================================================================
#pragma mark SPLogger
#pragma mark ====================================================================================

@interface SPLogger : NSObject

@property (nonatomic, weak,   readwrite) id<SPLoggerDelegate>	delegate;
@property (nonatomic, assign, readwrite) SPLogLevels			sharedLogLevel;
@property (nonatomic, assign, readwrite) BOOL                   writesToDisk;
@property (nonatomic, assign, readwrite) NSUInteger             maxLogfiles;
@property (nonatomic, assign, readwrite) unsigned long long     maxLogfileSize;
@property (nonatomic, strong,  readonly) NSURL                  *logfilesFolderURL;

+ (instancetype)sharedInstance;

- (void)logWithLevel:(SPLogLevels)level flag:(SPLogFlags)flag format:(NSString*)format, ...;

@end
