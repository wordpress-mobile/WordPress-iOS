#import <Foundation/Foundation.h>

/**
 *  @class  WPUserAgent
 *  @brief  Takes care of the user-agent logic for WPiOS.
 */
@interface WPUserAgent : NSObject

/**
 *  @brief      Default User-Agent header.
 */
+ (NSString *)defaultUserAgent;

/**
 *  @brief      WordPress custom User-Agent header.
 */
+ (NSString *)wordPressUserAgent;

/**
 *  @brief      Sets User-Agent header of all UIWebViews to be the WordPress one.
 */
+ (void)useWordPressUserAgentInUIWebViews;

@end
