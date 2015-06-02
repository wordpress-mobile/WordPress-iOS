#import <Foundation/Foundation.h>

/**
 *  @class      WPAppFilesManager
 *  @brief      Contains the logic for handling the WPiOS app files and directories.
 */
@interface WPAppFilesManager : NSObject

#pragma mark - Application directories

/**
 *  @brief      Changes the current working directory to the WordPress subdirectory.
 */
+ (void)changeWorkingDirectoryToWordPressSubdirectory;

@end
