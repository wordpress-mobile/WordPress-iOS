#import <Foundation/Foundation.h>

/**
 *  @class  WPUserAgent
 *  @brief  Takes care of the user-agent logic for WPiOS.
 */
@interface WPUserAgent : NSObject

/**
 *  @brief      WordPress custom User-Agent header.
 */
@property (nonatomic, strong, readonly) NSString *wordPressUserAgent;

/**
 *  @brief      Sets User-Agent header of all UIWebViews to be the WordPress one.
 */
- (void)useWordPressUserAgentInUIWebViews;

@end
