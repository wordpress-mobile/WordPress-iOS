#import "SharingAuthorizationWebViewController.h"
#import "Blog.h"
#import "Publicizer.h"

#pragma mark - SharingAuthorizationWebViewController

/**
 *	@brief	classify actions taken by web API
 */
typedef enum {
    AuthorizeActionNone,
    AuthorizeActionUnknown,
    AuthorizeActionRequest,
    AuthorizeActionVerify,
    AuthorizeActionDeny,
} AuthorizeAction;

/**
 *	@brief	override points
 */
@interface WPWebViewController () <UIWebViewDelegate>
- (IBAction)dismiss;
@end

@interface SharingAuthorizationWebViewController ()

/**
 *	@brief	verification loading -- dismiss on completion
 */
@property (nonatomic, assign) BOOL loadingVerify;
/**
 *	@brief	blog a publicizer is being authorized for
 */
@property (nonatomic, strong) Blog *blog;
/**
 *	@brief	publicize service being authorized
 */
@property (nonatomic, strong) Publicizer *publicizer;

@end

@implementation SharingAuthorizationWebViewController

+ (instancetype)controllerWithPublicizer:(Publicizer *)publicizer
                                 forBlog:(Blog *)blog
{
    NSParameterAssert(publicizer);
    NSParameterAssert(blog);
    
    SharingAuthorizationWebViewController *webViewController = [[self alloc] initWithNibName:@"WPWebViewController" bundle:nil];
    
    webViewController.blog = blog;
    webViewController.authToken = blog.authToken;
    webViewController.username = blog.usernameForSite;
    webViewController.password = blog.password;
    webViewController.wpLoginURL = [NSURL URLWithString:blog.loginUrl];
    webViewController.publicizer = publicizer;

    NSURL *authorizeURL = [NSURL URLWithString:publicizer.connect];
    webViewController.url = authorizeURL;
    
    return webViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // suppress sharing
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)showBottomToolbarIfNeeded
{
    // suppress navigation
}

- (IBAction)dismiss
{
    [super dismiss];
    if ([self.delegate respondsToSelector:@selector(authorizeDidCancel:)]) {
        [self.delegate authorizeDidCancel:self.publicizer];
    }
}

- (IBAction)suceed
{
    [super dismiss];
    if ([self.delegate respondsToSelector:@selector(authorizeDidSucceed:)]) {
        [self.delegate authorizeDidSucceed:self.publicizer];
    }
}

- (void)displayLoadError:(NSError *)error
{
    [super dismiss];
    if ([self.delegate respondsToSelector:@selector(authorize:didFailWithError:)]) {
        [self.delegate authorize:self.publicizer didFailWithError:error];
    }
}

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
                navigationType:(UIWebViewNavigationType)navigationType
{
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
    if (self.loadingVerify) {
        [self suceed];
    } else {
        [super webView:webView didFailLoadWithError:error];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.loadingVerify) {
        [self suceed];
    } else {
        [super webViewDidFinishLoad:webView];
    }
}

- (AuthorizeAction)requestedAuthorizeAction:(NSURLRequest *)request
{
    if (![request.URL.absoluteString hasPrefix:@"https://public-api.wordpress.com/connect/"]) {
        return AuthorizeActionNone;
    }
    
    NSRange requestRange = [request.URL.absoluteString rangeOfString:@"action=request"];
    if (requestRange.location != NSNotFound) {
        return AuthorizeActionRequest;
    }

    NSRange verifyRange = [request.URL.absoluteString rangeOfString:@"action=verify"];
    if (verifyRange.location != NSNotFound) {
        return AuthorizeActionVerify;
    }

    NSRange denyRange = [request.URL.absoluteString rangeOfString:@"action=deny"];
    if (denyRange.location != NSNotFound) {
        return AuthorizeActionDeny;
    }

    return AuthorizeActionUnknown;
}


@end
