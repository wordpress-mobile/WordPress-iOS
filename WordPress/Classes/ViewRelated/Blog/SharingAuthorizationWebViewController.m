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
@interface WPWebViewController ()
- (IBAction)dismiss;
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
@end

@interface SharingAuthorizationWebViewController ()
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) Publicizer *publicizer;
@end

@implementation SharingAuthorizationWebViewController

+ (instancetype)controllerWithPublicizer:(Publicizer *)publicizer
                                 forBlog:(Blog *)blog
{
    NSParameterAssert(publicizer);
    NSParameterAssert(blog);
    
    SharingAuthorizationWebViewController *webViewController = [[self alloc] initWithNibName:@"WPWebViewController" bundle:nil];

    webViewController.authToken = blog.authToken;
    webViewController.username = blog.usernameForSite;
    webViewController.password = blog.password;
    webViewController.wpLoginURL = [NSURL URLWithString:blog.loginUrl];
    
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
            [super dismiss];
            if ([self.delegate respondsToSelector:@selector(authorizeDidSucceed:)]) {
                [self.delegate authorizeDidSucceed:self.publicizer];
            }
            return NO;

        case AuthorizeActionDeny:
            [super dismiss];
            if ([self.delegate respondsToSelector:@selector(authorizeDidCancel:)]) {
                [self.delegate authorizeDidCancel:self.publicizer];
            }
            return NO;
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
        NSRange deniedRange = [request.URL.absoluteString rangeOfString:@"denied="];
        if (deniedRange.location != NSNotFound) {
            return AuthorizeActionDeny;
        }
        NSRange errorRange = [request.URL.absoluteString rangeOfString:@"error="];
        if (errorRange.location != NSNotFound) {
            return AuthorizeActionDeny;
        }
        return AuthorizeActionVerify;
    }

    return AuthorizeActionUnknown;
}


@end
