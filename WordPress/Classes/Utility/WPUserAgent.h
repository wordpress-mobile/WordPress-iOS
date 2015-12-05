#import <Foundation/Foundation.h>

/**
 *  @class  WPUserAgent
 *  @brief  Takes care of the user-agent logic for WPiOS.
 */
@interface WPUserAgent : NSObject

#pragma mark - Changing the user agent

/**
 *  @brief      Sets User-Agent header of all UIWebViews to be the WordPress one.
 */
- (void)useWordPressUserAgentInUIWebViews;

#pragma mark - Getting the user agent

/**
 *  @brief      Call this method to get the current user agent.
 *
 *  @returns    The current user agent.
 */
- (NSString *)currentUserAgent;

@end
