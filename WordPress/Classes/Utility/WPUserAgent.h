#import <Foundation/Foundation.h>

/**
 *  @class  WPUserAgent
 *  @brief  Takes care of the user-agent logic for WPiOS.
 */
@interface WPUserAgent : NSObject

/**
 *  @brief      Sets User-Agent header of all UIWebViews to be the WordPress one.
 */
- (void)useWordPressUserAgentInUIWebViews;

/**
 *  @brief      Get WordPress User-Agent header.
 *
 *  @returns    WordPress custom User-Agent header.
 */
- (NSString *)wordPressUserAgent;

@end
