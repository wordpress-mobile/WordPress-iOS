#import "WPAuthenticatedSessionWebViewManager.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"
#import "WPCookie.h"

@interface WPAuthenticatedSessionWebViewManager ()

@property (nonatomic, weak) id<WPAuthenticatedSessionWebViewManagerDelegate> delegate;
@property (nonatomic) BOOL forceLogin;

@end

@implementation WPAuthenticatedSessionWebViewManager

#pragma mark - Public

- (instancetype)initWithDelegate:(id<WPAuthenticatedSessionWebViewManagerDelegate>)delegate
{
    if (self = [super init]) {
        _delegate = delegate;
    }
    return self;
}

- (NSURLRequest *)URLRequestForAuthenticatedSession
{
    NSString *username = [self safeDelegateUsername];
    NSString *password = [self safeDelegatePassword];
    NSURL *destinationURL = [self safeDelegateDestinationURL];
    NSURL *loginURL = [self safeDelegateLoginURL];
    
    if (!self.forceLogin && username && password && ![WPCookie hasCookieForURL:destinationURL andUsername:username]) {
        self.forceLogin = YES;
    }
    
    NSURL *webURL;
    if (self.forceLogin) {
        if (loginURL != nil) {
            webURL = loginURL;
        } else { //try to guess the login URL
            webURL = [[NSURL alloc] initWithScheme:destinationURL.scheme host:destinationURL.host path:@"/wp-login.php"];
        }
    } else {
        webURL = destinationURL;
    }
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL];
    request.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    if (self.forceLogin) {
        NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=%@",
                                  [username stringByUrlEncoding],
                                  [password stringByUrlEncoding],
                                  [[destinationURL absoluteString] stringByUrlEncoding]];
        
        if (loginURL != nil )
            [request setURL: loginURL];
        else
            [request setURL:[[NSURL alloc] initWithScheme:destinationURL.scheme host:destinationURL.host path:@"/wp-login.php"]];
        
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
        NSString *username = [self safeDelegateUsername];
        NSString *password = [self safeDelegatePassword];
        
        if (username && password) {
            DDLogInfo(@"WP is asking for credentials, let's login first");
            self.forceLogin = YES;
            [webView loadRequest:[self URLRequestForAuthenticatedSession]];
            shouldStartLoad = NO;
        }
    }
    
    return shouldStartLoad;
}

#pragma mark - Private

- (NSString *)safeDelegateUsername
{
    NSString *username = nil;
    if ([self.delegate respondsToSelector:@selector(username)]) {
        username = [self.delegate username];
    }
    return username;
}

- (NSString *)safeDelegatePassword
{
    NSString *password = nil;
    if ([self.delegate respondsToSelector:@selector(password)]) {
        password = [self.delegate password];
    }
    return password;
}

- (NSURL *)safeDelegateDestinationURL
{
    NSURL *destinationURL = nil;
    if ([self.delegate respondsToSelector:@selector(destinationURL)]) {
        destinationURL = [self.delegate destinationURL];
    }
    return destinationURL;
}

- (NSURL *)safeDelegateLoginURL
{
    NSURL *loginURL = nil;
    if ([self.delegate respondsToSelector:@selector(loginURL)]) {
        loginURL = [self.delegate loginURL];
    }
    return loginURL;
}

@end
