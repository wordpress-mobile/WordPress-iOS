#import <UIKit/UIKit.h>

@class Blog;
@class WPAccount;

#pragma mark - WPWebViewController

@interface WPWebViewController : UIViewController<UIWebViewDelegate>

/**
 *	@brief		Represents the Endpoint URL to render
 */
@property (nonatomic, strong) NSURL     *url;

/**
 *  @brief      A custom options button to show instead of the share button. Must be set before presented.
 */
@property (nonatomic, strong) UIBarButtonItem          *optionsButton;

/**
 *	@brief		Optionally suppresses navigation and sharing
 */
@property (nonatomic, assign) BOOL      secureInteraction;

/**
 *  @brief  When true adds a custom referrer to NSURLRequest.
 */
@property (nonatomic, assign) BOOL addsWPComReferrer;

/**
 *  @brief Use the provided blog to authenticate the web view.
 */
- (void)authenticateWithBlog:(Blog *)blog;

/**
 *  @brief Use the provided account to authenticate the web view.
 */
- (void)authenticateWithAccount:(WPAccount *)account;

/**
 *  @brief Use the default account to authenticate the web view.
 */
- (void)authenticateWithDefaultAccount;

/**
 *	@brief		Dismiss modal presentation
 */
- (IBAction)dismiss;

@end
