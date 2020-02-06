/*@import WebKit;

#import "SharingAuthorizationWebViewController.h"
#import "Blog.h"
#import "WPUserAgent.h"
#import "WordPress-Swift.h"
 */
import WebKit

/*
 //@protocol SharingAuthorizationDelegate <NSObject>
 //- (void)authorizeDidSucceed:(PublicizeService *)publicizer;
 //- (void)authorize:(PublicizeService *)publicizer didFailWithError:(NSError *)error;
 //- (void)authorizeDidCancel:(PublicizeService *)publicizer;
 //@end
 */

@objc
protocol SharingAuthorizationDelegate: NSObjectProtocol {
    @objc
    func authorize(_ publicizer: PublicizeService, didFailWithError error: NSError)

    @objc
    func authorizeDidSucceed(_ publicizer: PublicizeService)

    @objc
    func authorizeDidCancel(_ publicizer: PublicizeService)
}

/*
#pragma mark - SharingAuthorizationWebViewController
 */

/**
 *    @brief    classify actions taken by web API
 */
/*
typedef NS_ENUM(NSInteger, AuthorizeAction) {
    AuthorizeActionNone,
    AuthorizeActionUnknown,
    AuthorizeActionRequest,
    AuthorizeActionVerify,
    AuthorizeActionDeny,
};
 */

@objc
class SharingAuthorizationWebViewController: WPWebViewController {
    /// Classify actions taken by the web API
    ///
    private enum AuthorizeAction: Int {
        case none
        case unknown
        case request
        case verify
        case deny
    }
/*
static NSString * const SharingAuthorizationLoginURL = @"https://wordpress.com/wp-login.php";
static NSString * const SharingAuthorizationPrefix = @"https://public-api.wordpress.com/connect/";
static NSString * const SharingAuthorizationRequest = @"action=request";
static NSString * const SharingAuthorizationVerify = @"action=verify";
static NSString * const SharingAuthorizationDeny = @"action=deny";
 */
    private static let loginURL = "https://wordpress.com/wp-login.php"
    private static let authorizationPrefix = "https://public-api.wordpress.com/connect/"
    private static let requestActionParameter = "action=request"
    private static let verifyActionParameter = "action=verify"
    private static let denyActionParameter = "action=deny"

/*
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
 */
    private static let declinePath = "/decline"
    private static let userRefused = "oauth_problem=user_refused"
    private static let authorizationDenied = "denied="
    private static let accessDenied = "error=access_denied"


//@interface SharingAuthorizationWebViewController ()

/**
 *    @brief    verification loading -- dismiss on completion
 */
//@property (nonatomic, assign) BOOL loadingVerify;
    private var loadingVerify: Bool = false

/**
 *    @brief    publicize service being authorized
 */
//@property (nonatomic, strong) PublicizeService *publicizer;
    private let publicizer: PublicizeService


//@property (nonatomic, strong) NSMutableArray *hosts;
    private var hosts = [String]()

// From old header...
//@property (nonatomic, weak) id<SharingAuthorizationDelegate> delegate;
    private let delegate: SharingAuthorizationDelegate

/*
@end

@implementation SharingAuthorizationWebViewController
*/

    /*
+ (instancetype)controllerWithPublicizer:(PublicizeService *)publicizer
                           connectionURL:(NSURL *)connectionURL
                                 forBlog:(Blog *)blog
{
    NSParameterAssert(publicizer);
    NSParameterAssert(blog);
    
    SharingAuthorizationWebViewController *webViewController = [[self alloc] initWithNibName:@"WPWebViewController" bundle:nil];

    webViewController.authenticator = [[WebViewAuthenticator alloc] initWithBlog:blog];
    webViewController.publicizer = publicizer;
    webViewController.secureInteraction = YES;
    webViewController.url = connectionURL;
    
    return webViewController;
}
 */
    @objc
    init(with publicizer: PublicizeService, url: URL, for blog: Blog, delegate: SharingAuthorizationDelegate) {
        self.delegate = delegate
        self.publicizer = publicizer

        super.init(nibName: "WPWebViewController", bundle: nil)

        self.authenticator = WebViewAuthenticator(blog: blog)
        self.secureInteraction = true
        self.url = url
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

/*
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self cleanup];
}
     */

     // MARK: - View Lifecycle

     override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)

         cleanup()
     }

/*
#pragma mark - Instance Methods

- (NSMutableArray *)hosts
{
    if (!_hosts) {
        _hosts = [NSMutableArray array];
    }
    return _hosts;
}

- (void)saveHostFromURL:(NSURL *)url
{
    NSString *host = url.host;
    if (!host || [host containsString:@"wordpress"] || [self.hosts containsObject:host]) {
        return;
    }
    NSArray *components = [host componentsSeparatedByString:@"."];
    // A bit of paranioa here. The components should never be less than two but just in case...
    NSString *hostName = ([components count] > 1) ? [components objectAtIndex:[components count] - 2] : [components firstObject];
    [self.hosts addObject:hostName];
}
     */

    // MARK: - Misc

    func saveHost(from url: URL) {
        guard let host = url.host,
            !host.contains("wordpress"),
            !hosts.contains(host) else {
                return
        }

        let components = host.components(separatedBy: ".")

        // A bit of paranioa here. The components should never be less than two but just in case...
        guard let hostName = components.count > 1 ? components[components.count - 2] : components.first else {
            return
        }

        hosts.append(hostName)
    }

/*
- (void)cleanup
{
    // Log out of the authenticed service.
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        for (NSString *host in self.hosts) {
            if ([cookie.domain containsString:host]) {
                [storage deleteCookie:cookie];
            }
        }
    }
}
    */

    func cleanup() {
        let storage = HTTPCookieStorage.shared

        guard let cookies = storage.cookies else {
            // Nothing to cleanup
            return
        }

        for cookie in cookies {
            for host in hosts {
                if cookie.domain.contains(host) {
                    storage.deleteCookie(cookie)
                }
            }
        }
    }

/*
- (IBAction)dismiss
{
    if ([self.delegate respondsToSelector:@selector(authorizeDidCancel:)]) {
        [self.delegate authorizeDidCancel:self.publicizer];
    }
}
     */

    @IBAction
    override func dismiss() {
        delegate.authorizeDidCancel(publicizer)
    }

    /*
- (void)handleAuthorizationAllowed
{
    // Note: There are situations where this can be called in error due to how
    // individual services choose to reply to an authorization request.
    // Delegates should expect to handle a false positive.
    if ([self.delegate respondsToSelector:@selector(authorizeDidSucceed:)]) {
        [self.delegate authorizeDidSucceed:self.publicizer];
    }
}
     */

    private func handleAuthorizationAllowed() {
        // Note: There are situations where this can be called in error due to how
        // individual services choose to reply to an authorization request.
        // Delegates should expect to handle a false positive.
        delegate.authorizeDidSucceed(publicizer)
    }

    /*
- (void)displayLoadError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(authorize:didFailWithError:)]) {
        [self.delegate authorize:self.publicizer didFailWithError:error];
    }
}
     */

    private func displayLoadError(error: NSError) {
        delegate.authorize(self.publicizer, didFailWithError: error)
    }

    /*
- (AuthorizeAction)requestedAuthorizeAction:(NSURL *)url
{
    NSString *requested = [url absoluteString];
    
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
     */

    private func requestedAuthorizeAction(url: URL) -> AuthorizeAction {
        let requested = url.absoluteString

        // Path oauth declines are handled by a redirect to a path.com URL, so check this first.
        if requested.range(of: SharingAuthorizationWebViewController.declinePath) != nil {
            return .deny
        }

        if requested.hasPrefix(SharingAuthorizationWebViewController.authorizationPrefix) {
            return .none
        }

        if requested.range(of: SharingAuthorizationWebViewController.requestActionParameter) != nil {
            return .request
        }

        // Check the rest of the various decline ranges
        if requested.range(of: SharingAuthorizationWebViewController.denyActionParameter) != nil {
            return .deny
        }

        // LinkedIn
        if requested.range(of: SharingAuthorizationWebViewController.userRefused) != nil {
            return .deny
        }

        // Facebook and Google+
        if requested.range(of: SharingAuthorizationWebViewController.accessDenied) != nil {
            return .deny
        }

        // If we've made it this far and verifyRange is found then we're *probably*
        // verifying the oauth request.  There are edge cases ( :cough: tumblr :cough: )
        // where verification is declined and we get a false positive.
        if requested.range(of: SharingAuthorizationWebViewController.verifyActionParameter) != nil {
            return .verify
        }

        return .unknown
    }
}

/*
#pragma mark - WKWebViewNavigationDelegate
     */
// MARK: - WKNavigationDelegate

extension SharingAuthorizationWebViewController {

/*
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    // Prevent a second verify load by someone happy clicking.
    if (self.loadingVerify) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    AuthorizeAction action = [self requestedAuthorizeAction:navigationAction.request.URL];
    switch (action) {
        case AuthorizeActionNone:
        case AuthorizeActionUnknown:
        case AuthorizeActionRequest:
            [super webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
            return;

        case AuthorizeActionVerify:
            self.loadingVerify = YES;
            decisionHandler(WKNavigationActionPolicyAllow);
            return;

        case AuthorizeActionDeny:
            [self dismiss];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
    }
}
     */
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        // Prevent a second verify load by someone happy clicking.
        guard !loadingVerify,
            let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
        }

        let action = requestedAuthorizeAction(url: url)

        switch action {
        case .none:
            fallthrough
        case .unknown:
            fallthrough
        case .request:
            super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
        case .verify:
            loadingVerify = true
            decisionHandler(.allow)
        case .deny:
            decisionHandler(.cancel)
            dismiss()
        }
    }

/*
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (self.loadingVerify && error.code == NSURLErrorCancelled) {
        // Authenticating to Facebook and Twitter can return an false
        // NSURLErrorCancelled (-999) error. However the connection still succeeds.
        [self handleAuthorizationAllowed];
        return;
    }
    [super webView:webView didFailNavigation:navigation withError:error];
}
     */
    override func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if loadingVerify && (error as NSError).code == NSURLErrorCancelled {
            // Authenticating to Facebook and Twitter can return an false
            // NSURLErrorCancelled (-999) error. However the connection still succeeds.
            handleAuthorizationAllowed()
            return
        }

        super.webView(webView, didFail: navigation, withError: error)
    }


    /*
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    [self saveHostFromURL:webView.URL];

    if (self.loadingVerify) {
        [self handleAuthorizationAllowed];
    } else {
        [super webView:webView didFinishNavigation:navigation];
    }
}
*/

    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            saveHost(from: url)
        }

        if loadingVerify {
            handleAuthorizationAllowed()
        } else {
            super.webView(webView, didFinish: navigation)
        }
    }

    /*
@end
*/

}
