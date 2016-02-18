#import "SharingAuthorizationWebViewController.h"
#import "Blog.h"
#import "WordPressAppDelegate.h"
#import "WPUserAgent.h"
#import "WordPress-Swift.h"

#pragma mark - SharingAuthorizationWebViewController

/**
 *	@brief	classify actions taken by web API
 */
typedef NS_ENUM(NSInteger, AuthorizeAction) {
    AuthorizeActionNone,
    AuthorizeActionUnknown,
    AuthorizeActionRequest,
    AuthorizeActionVerify,
    AuthorizeActionDeny,
};

static NSString * const SharingAuthorizationLoginURL = @"https://wordpress.com/wp-login.php";
static NSString * const SharingAuthorizationPrefix = @"https://public-api.wordpress.com/connect/";
static NSString * const SharingAuthorizationRequest = @"action=request";
static NSString * const SharingAuthorizationVerify = @"action=verify";
static NSString * const SharingAuthorizationDeny = @"action=deny";

// Special handling for the inconsistent way that services respond to a user's choice to decline oauth authorization.
// Tumblr is uncooporative and doesn't respond in a way that clearly indicates failure.
// Path does not set the action param or call the callback. It forwards to its own URL ending in /decline.
static NSString * const SharingAuthorizationPathDecline = @"/decline";
// LinkedIn
static NSString * const SharingAuthorizationUserRefused = @"oauth_problem=user_refused";
// Twitter
static NSString * const SharingAuthorizationDenied = @"denied=";
// Facebook and Google+
static NSString * const SharingAuthorizationAccessDenied = @"error=access_denied";


@interface SharingAuthorizationWebViewController ()

/**
 *	@brief	verification loading -- dismiss on completion
 */
@property (nonatomic, assign) BOOL loadingVerify;
/**
 *	@brief	publicize service being authorized
 */
@property (nonatomic, strong) PublicizeService *publicizer;

@end

@implementation SharingAuthorizationWebViewController

+ (instancetype)controllerWithPublicizer:(PublicizeService *)publicizer
                           connectionURL:(NSURL *)connectionURL
                                 forBlog:(Blog *)blog
{
    NSParameterAssert(publicizer);
    NSParameterAssert(blog);
    
    SharingAuthorizationWebViewController *webViewController = [[self alloc] initWithNibName:@"WPWebViewController" bundle:nil];

    webViewController.authToken = blog.authToken;
    webViewController.username = blog.jetpackAccount.username ?: blog.account.username;
    webViewController.wpLoginURL = [NSURL URLWithString:SharingAuthorizationLoginURL];
    webViewController.publicizer = publicizer;
    webViewController.secureInteraction = YES;
    webViewController.url = connectionURL;
    
    return webViewController;
}


#pragma mark - Instance Methods

- (IBAction)dismiss
{
    if ([self.delegate respondsToSelector:@selector(authorizeDidCancel:)]) {
        [self.delegate authorizeDidCancel:self.publicizer];
    }
}

- (void)handleAuthorizationAllowed
{
    // Note: There are situations where this can be called in error due to how
    // individual services choose to reply to an authorization request.
    // Delegates should expect to handle a false positive.
    if ([self.delegate respondsToSelector:@selector(authorizeDidSucceed:)]) {
        [self.delegate authorizeDidSucceed:self.publicizer];
    }
}

- (void)displayLoadError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(authorize:didFailWithError:)]) {
        [self.delegate authorize:self.publicizer didFailWithError:error];
    }
}

- (AuthorizeAction)requestedAuthorizeAction:(NSURLRequest *)request
{
    NSString *requested = [request.URL absoluteString];

    // Path oauth declines are handled by a redirect to a path.com URL, so check this first.
    NSRange denyRange = [requested rangeOfString:SharingAuthorizationPathDecline];
    if (denyRange.location != NSNotFound) {
        return AuthorizeActionDeny;
    }

    if (![requested hasPrefix:SharingAuthorizationPrefix]) {
        return AuthorizeActionNone;
    }

    NSRange requestRange = [requested rangeOfString:SharingAuthorizationRequest];
    if (requestRange.location != NSNotFound) {
        return AuthorizeActionRequest;
    }

    // Check the rest of the various decline ranges
    denyRange = [requested rangeOfString:SharingAuthorizationDeny];
    if (denyRange.location != NSNotFound) {
        return AuthorizeActionDeny;
    }
    // LinkedIn
    denyRange = [requested rangeOfString:SharingAuthorizationUserRefused];
    if (denyRange.location != NSNotFound) {
        return AuthorizeActionDeny;
    }
    // Twitter
    denyRange = [requested rangeOfString:SharingAuthorizationDenied];
    if (denyRange.location != NSNotFound) {
        return AuthorizeActionDeny;
    }
    // Facebook and Google+
    denyRange = [requested rangeOfString:SharingAuthorizationAccessDenied];
    if (denyRange.location != NSNotFound) {
        return AuthorizeActionDeny;
    }

    // If we've made it this far and verifyRange is found then we're *probably*
    // verifying the oauth request.  There are edge cases ( :cough: tumblr :cough: )
    // where verification is declined and we get a false positive.
    NSRange verifyRange = [requested rangeOfString:SharingAuthorizationVerify];
    if (verifyRange.location != NSNotFound) {
        return AuthorizeActionVerify;
    }

    return AuthorizeActionUnknown;
}


#pragma mark - WebView Delegate Methods

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
                navigationType:(UIWebViewNavigationType)navigationType
{
    // Prevent a second verify load by someone happy clicking.
    if (self.loadingVerify) {
        return NO;
    }

    AuthorizeAction action = [self requestedAuthorizeAction:request];
    switch (action) {
        case AuthorizeActionNone:
        case AuthorizeActionUnknown:
        case AuthorizeActionRequest:
            return [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];

        case AuthorizeActionVerify:
            self.loadingVerify = YES;
            return YES;

        case AuthorizeActionDeny:
            [self dismiss];
            return NO;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (self.loadingVerify && error.code == NSURLErrorCancelled) {
        // Authenticating to Facebook and Twitter can return an false
        // NSURLErrorCancelled (-999) error. However the connection still succeeds.
        [self handleAuthorizationAllowed];
        return;
    }
    [super webView:webView didFailLoadWithError:error];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.loadingVerify) {
        [self handleAuthorizationAllowed];
    } else {
        [super webViewDidFinishLoad:webView];
    }
}

@end
