#import <UIKit/UIKit.h>

@protocol LinkOptionsDelegate;

#pragma mark - WPWebViewController

@interface WPWebViewController : UIViewController<UIWebViewDelegate>

/**
 *	@brief		Represents the Endpoint URL to render
 */
@property (nonatomic, strong) NSURL     *url;

/**
 *	@brief		Login URL that should be used to authenticate the user.
 */
@property (nonatomic, strong) NSURL     *wpLoginURL;

/**
 *	@brief		Username. Optional, will be used in case the endpoint requires authentication.
 */
@property (nonatomic, strong) NSString  *username;

/**
 *	@brief		Password. Optional, will be used in case the endpoint requires authentication.
 */
@property (nonatomic, strong) NSString  *password;

/**
 *	@brief		Bearer Token. Optional, will be used in case the endpoint requires authentication.
 */
@property (nonatomic, strong) NSString  *authToken;

/**
 *	@brief		Optionally scrolls the endpoint to the bottom of the screen, automatically.
 */
@property (nonatomic, assign) BOOL      shouldScrollToBottom;

/**
 *	@brief		Optionally suppresses navigation and sharing
 */
@property (nonatomic, assign) BOOL      secureInteraction;

/**
 *  @brief  When true adds a custom referrer to NSURLRequest.
 */
@property (nonatomic, assign) BOOL addsWPComReferrer;

/**
 * @brief Optional, delegate to handle taps on the link options/right navigation button.
 */
@property (nonatomic, weak) id<LinkOptionsDelegate> linkOptionsDelegate;

/**
 * @brief Optional, dictionary to pass back to the delegate when the right navigation button is tapped.
 */
@property (nonatomic, strong) NSDictionary *linkOptionsParams;

/**
 *	@brief		Dismiss modal presentation
 */
- (IBAction)dismiss;

/**
 *	@brief      Helper method to initialize a WebViewController Instance
 *
 *	@param		url         The URL that needs to be rendered
 *  @returns                A WPWebViewController instance ready to be pushed.
 */
+ (instancetype)webViewControllerWithURL:(NSURL *)url;

/**
 *	@brief      Helper method to initialize a WebViewController Instance with a 
 *              custom options button
 *
 *	@param		url         The URL that needs to be rendered
 *  @param      button      A custom options button to display instead of the
 *                          default share button.
 *  @returns                A WPWebViewController instance ready to be pushed.
 */
+ (instancetype)webViewControllerWithURL:(NSURL *)url
                           optionsButton:(UIBarButtonItem *)button;

@end

/**
 * @brief Delegate to handle taps on the top right navigation button.
 */
@protocol LinkOptionsDelegate

/**
 *	@brief      Method to be invoked when the user taps on the link options/right navigation button.
 *
 *	@param      viewController ViewController where the button resides.
 *  @param      optionsButton Right navigation button item tapped
 *  @param      optionsParams A dictionary containing previously set linkOptionsParams.
 */
- (void)linkOptionsTappedOnViewController:(UIViewController *)viewController
                            optionsButton:(UIBarButtonItem *)optionsButton
                                   params:(NSDictionary *)optionsParams;

@end
