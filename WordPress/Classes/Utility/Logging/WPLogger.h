#import <Foundation/Foundation.h>

@class DDFileLogger;

/**
 *  @class      WPlogger
 *  @brief      This module takes care of the logging setup for WPiOS.
 */
@interface WPLogger : NSObject

@property (nonatomic, strong, readonly) DDFileLogger * _Nonnull fileLogger;

#pragma mark - Reading from the log

/**
 *  @brief      Retrieves log data from the log files.
 * 
 *  @param      maxSize     The maximum number of bytes to retrieve from the log files.
 *
 *  @returns    The requested log data.
 */
- (NSString * _Nonnull)getLogFilesContentWithMaxSize:(NSInteger)maxSize;

+ (void)configureLoggerLevelWithExtraDebug;

/**
 * @brief A shared instance that can be called from anywhere
 */
+ (WPLogger * _Nonnull)shared;

@end
