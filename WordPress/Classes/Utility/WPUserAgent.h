#import <Foundation/Foundation.h>

/**
 *  @class  WPUserAgent
 *  @brief  Takes care of the user-agent logic for WPiOS.
 */
@interface WPUserAgent : NSObject

/**
 *  @brief      Sets the App's user agent to be the default one.
 */
- (void)useDefaultUserAgent;

/**
 *  @brief      Sets the App's user agent to be the WordPress one.
 */
- (void)useAppUserAgent;

/**
 *  @brief      Call this method to get the current user agent.
 *
 *  @returns    The current user agent.
 */
- (NSString *)applicationUserAgent;

@end
