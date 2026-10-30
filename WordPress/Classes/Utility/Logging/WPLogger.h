#import <Foundation/Foundation.h>

@class DDFileLogger;

/**
 *  @class      WPlogger
 *  @brief      This module takes care of the logging setup for WPiOS.
 */
@interface WPLogger : NSObject

@property (nonatomic, strong, readonly) DDFileLogger * _Nonnull fileLogger;

+ (void)configureLoggerLevelWithExtraDebug;

/**
 * @brief A shared instance that can be called from anywhere
 */
+ (WPLogger * _Nonnull)shared;

/**
 * @brief Deletes all the logs from the device
 */
- (void)deleteAllLogs;

/**
 * @brief Deletes all the old archived logs from the device
 */
- (void)deleteArchivedLogs;

@end
