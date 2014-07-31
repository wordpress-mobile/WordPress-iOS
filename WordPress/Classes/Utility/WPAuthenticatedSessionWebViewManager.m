#import "WPAuthenticatedSessionWebViewManager.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"
#import "WPCookie.h"

@interface WPAuthenticatedSessionWebViewManager ()

@property (nonatomic) BOOL forceLogin;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;
@property (nonatomic) NSURL *destinationURL;
@property (nonatomic) NSURL *loginURL;

@end

@implementation WPAuthenticatedSessionWebViewManager

#pragma mark - Public

- (instancetype)initWithUsername:(NSString *)username
                        password:(NSString *)password
                  destinationURL:(NSURL *)destinationURL
                        loginURL:(NSURL *)loginURL
{
    if (self = [super init]) {
        _username = username;
        _password = password;
        _destinationURL = destinationURL;
        _loginURL = loginURL;
    }
    return self;
}

- (NSURLRequest *)URLRequestForAuthenticatedSession
{
    if (!self.forceLogin && self.username && self.password && ![WPCookie hasCookieForURL:self.destinationURL andUsername:self.username]) {
        self.forceLogin = YES;
    }
    
    NSURL *webURL;
    if (self.forceLogin) {
        if (self.loginURL != nil) {
            webURL = self.loginURL;
        } else { //try to guess the login URL
            webURL = [[NSURL alloc] initWithScheme:self.destinationURL.scheme host:self.destinationURL.host path:@"/wp-login.php"];
        }
    } else {
        webURL = self.destinationURL;
    }
    
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL];
    request.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    if (self.forceLogin) {
        NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=%@",
                                  [self.username stringByUrlEncoding],
                                  [self.password stringByUrlEncoding],
                                  [[self.destinationURL absoluteString] stringByUrlEncoding]];
        
        if (self.loginURL != nil )
            [request setURL:self.loginURL];
        else
            [request setURL:[[NSURL alloc] initWithScheme:self.destinationURL.scheme host:self.destinationURL.host path:@"/wp-login.php"]];
        
        [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"%d", [request_body length]] forHTTPHeaderField:@"Content-Length"];
        [request addValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setHTTPMethod:@"POST"];
    }
    
    return request;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL shouldStartLoad = YES;
    
    NSURL *requestedURL = [request URL];
    NSString *requestedURLAbsoluteString = [requestedURL absoluteString];
    
    if(!self.forceLogin && [requestedURLAbsoluteString rangeOfString:@"wp-login.php"].location != NSNotFound) {
        if (self.username && self.password) {
            DDLogInfo(@"WP is asking for credentials, let's login first");
            self.forceLogin = YES;
            [webView loadRequest:[self URLRequestForAuthenticatedSession]];
            shouldStartLoad = NO;
        }
    }
    
    return shouldStartLoad;
}

@end
