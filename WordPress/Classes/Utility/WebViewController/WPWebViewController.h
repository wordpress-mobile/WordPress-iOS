#import <UIKit/UIKit.h>
@import WebKit;

@class Blog;
@class WPAccount;
@class WebViewControllerConfiguration;
@class RequestAuthenticator;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - WPWebViewController

@interface WPWebViewController : UIViewController<WKNavigationDelegate>

- (instancetype)initWithConfiguration:(WebViewControllerConfiguration *)configuration;

/**
 *    @brief        Represents the Endpoint URL to render
 */
@property (nonatomic, strong, nullable) NSURL     *url;

/**
 *  @brief      A custom options button to show instead of the share button. Must be set before presented.
 */
@property (nonatomic, strong, nullable) UIBarButtonItem *optionsButton;

/**
 *    @brief        Optionally suppresses navigation and sharing
 */
@property (nonatomic, assign) BOOL      secureInteraction;

/**
 *  @brief  When true adds a custom referrer to NSURLRequest.
 */
@property (nonatomic, assign) BOOL addsWPComReferrer;

@property (nonatomic, strong, nullable) RequestAuthenticator *authenticator;

/**
 *	@brief		Dismiss modal presentation
 */
- (IBAction)dismiss;

@end

NS_ASSUME_NONNULL_END
