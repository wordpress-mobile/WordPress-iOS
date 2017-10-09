#import <UIKit/UIKit.h>

@class Blog;
@class WPAccount;
@class WebViewAuthenticator;

#pragma mark - WPWebViewController

@interface WPWebViewController : UIViewController<UIWebViewDelegate>

/**
 *    @brief        Represents the Endpoint URL to render
 */
@property (nonatomic, strong) NSURL     *url;

/**
 *  @brief      A custom options button to show instead of the share button. Must be set before presented.
 */
@property (nonatomic, strong) UIBarButtonItem          *optionsButton;

/**
 *    @brief        Optionally suppresses navigation and sharing
 */
@property (nonatomic, assign) BOOL      secureInteraction;

/**
 *  @brief  When true adds a custom referrer to NSURLRequest.
 */
@property (nonatomic, assign) BOOL addsWPComReferrer;

@property (nonatomic, strong) WebViewAuthenticator *authenticator;

/**
 *	@brief		Dismiss modal presentation
 */
- (IBAction)dismiss;

@end
