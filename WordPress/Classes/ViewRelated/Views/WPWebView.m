#import "WPWebView.h"
#import "Reachability.h"
#import "ReachabilityUtils.h"
#import "AFHTTPRequestOperation.h"
#import "WordPressAppDelegate.h"
#import "UIColor+Helpers.h"
#import "UIDevice+Helpers.h"
#import "WPUserAgent.h"

NSString *refreshedWithOutValidRequestNotification = @"refreshedWithOutValidRequestNotification";

@interface WPWebView ()

@property (strong, nonatomic) EGORefreshTableHeaderView *refreshHeaderView;
@property (strong, nonatomic) NSMutableDictionary *defaultHeaders;
@property (strong, nonatomic) NSDate *lastWebViewRefreshDate;
@property (strong, nonatomic) AFHTTPRequestOperation *currentHTTPRequestOperation;
@property (strong, nonatomic) NSURLRequest *currentRequest;
@property (strong, nonatomic) Reachability *reachability;
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) NSURL *baseURLFallback;

- (void)setupSubviews;
- (void)setupHeaders;
- (void)setLoading:(BOOL)value;
- (void)setDefaultHeader:(NSString *)header value:(NSString *)value;

@end

@implementation WPWebView

@synthesize delegate;
@synthesize canGoBack;
@synthesize canGoForward;
@synthesize loading;
@synthesize request;
@synthesize scalesPageToFit;

@synthesize refreshHeaderView;
@synthesize defaultHeaders;
@synthesize lastWebViewRefreshDate;
@synthesize currentHTTPRequestOperation;
@synthesize currentRequest;
@synthesize reachability;
@synthesize webView;
@synthesize scrollView;
@synthesize baseURLFallback;
@synthesize useWebViewLoading;

- (void)dealloc
{
    if ([self.scrollView observationInfo]) {
        [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    }

    webView.delegate = nil;

    if ([webView isLoading]) {
        [webView stopLoading];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupSubviews];
        [self setupHeaders];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
        [self setupHeaders];
    }
    return self;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];

    if (!didSetScrollViewContentSize) {
        didSetScrollViewContentSize=YES;
        // Set the conetnt size so the view's initial state is not scrollable.
        scrollView.contentSize = self.frame.size;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (![keyPath isEqualToString:@"contentOffset"]) {
        return;
    }

    CGPoint newValue = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
    CGPoint oldValue = [[change objectForKey:NSKeyValueChangeOldKey] CGPointValue];

    if (newValue.y == oldValue.y) {
        return;
    }
}

#pragma mark -
#pragma mark Drawing Methods

- (void)setupHeaders
{
    self.defaultHeaders = [NSMutableDictionary dictionary];

    // Accept-Encoding HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
    [self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];

    // Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
    [self setDefaultHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes]];

    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    NSString *userAgent = [[WordPressAppDelegate sharedInstance].userAgent currentUserAgent];
    [self setDefaultHeader:@"User-Agent" value:userAgent];
}

- (void)setupSubviews
{
    self.backgroundColor = [UIColor whiteColor];

    CGRect frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);

    // WebView
    self.webView = [[UIWebView alloc] initWithFrame:frame];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.scalesPageToFit = YES;
    webView.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.95 alpha:1.0];
    
    NSString *webViewBackground = [NSString stringWithFormat:@"document.body.style.background = '#%@';", [[WPStyleGuide itsEverywhereGrey] hexString]];
    [webView stringByEvaluatingJavaScriptFromString:webViewBackground];
    
    [self addSubview:webView];
    webView.delegate = self;

    // Scroll View - assigning, not retaining, so don't release later.
    if ([webView respondsToSelector:@selector(scrollView)]) {
        self.scrollView = webView.scrollView;
    } else {
        for (UIView* subView in webView.subviews) {
            if ([subView isKindOfClass:[UIScrollView class]]) {
                self.scrollView = (UIScrollView*)subView;
            }
        }
    }
    // Speed up scrolling!
    self.scrollView.decelerationRate = 1.0f;

    // Nix the scrollview's background.
    for (UIView *view in scrollView.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            view.alpha = 0.0;
            view.hidden = YES;
        }
    }

    // Pull to refresh
    if (self.refreshHeaderView == nil) {
        scrollView.delegate = self;
        CGRect frm = CGRectMake(0.0f, 0.0f - scrollView.bounds.size.height, scrollView.frame.size.width, scrollView.bounds.size.height);
        self.refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:frm];
        refreshHeaderView.delegate = self;
        [scrollView addSubview:refreshHeaderView];
    }
    self.lastWebViewRefreshDate = [NSDate date];
    //  update the last update date
    [refreshHeaderView refreshLastUpdatedDate];

    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

#pragma mark -
#pragma mark Instance Methods

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value
{
    [defaultHeaders setValue:value forKey:header];
}

- (Reachability *)reachability
{
    // lazy load.
    if (!reachability) {
        self.reachability = [Reachability reachabilityForInternetConnection];
    }
    return reachability;
}

- (NSURLRequest *)request
{
    if (currentRequest) {
        return currentRequest;
    } else if ([webView request]) {
        return [webView request];
    }
    return nil;
}

- (void)setCurrentRequest:(NSURLRequest *)req
{
    if ([req isEqual:currentRequest]) {
        return;
    }

    // Ajax requests may return about:blank and we want to ignore these.
    if ([@"about:blank" isEqualToString:[[req URL] absoluteString]]) {
        return;
    }

    currentRequest = req;
}

- (void)setCurrentHTTPRequestOperation:(AFHTTPRequestOperation *)newCurrentHTTPRequestOperation
{
    if (currentHTTPRequestOperation){
        if (currentHTTPRequestOperation.isExecuting) {
            [currentHTTPRequestOperation cancel];
        }
         currentHTTPRequestOperation = nil;
    }
    currentHTTPRequestOperation = newCurrentHTTPRequestOperation;
}

- (NSURL *)currentURL
{
    return [[self currentRequest] URL];
}

#pragma mark -
#pragma mark Loading Methods

- (BOOL)isLoading
{
    return loading;
}

- (void)setLoading:(BOOL)value
{
    loading = value;
    if (loading) {
        [self showRefreshingState];
    } else {
        [self hideRefreshingState];
    }
}

- (void)loadData:(NSData *)data
        MIMEType:(NSString *)MIMEType
textEncodingName:(NSString *)encodingName
         baseURL:(NSURL *)baseURL
{
    self.currentHTTPRequestOperation = nil;
    [self setLoading:YES];
    [webView loadData:data MIMEType:MIMEType textEncodingName:encodingName baseURL:baseURL];
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
    self.currentHTTPRequestOperation = nil;
    [self setLoading:YES];
    [webView loadHTMLString:string baseURL:baseURL];
}

- (void)loadRequest:(NSURLRequest *)aRequest
{
    if (loading) {
        [self stopLoading];
    }

    if (![[self reachability] isReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }

    [self setLoading:YES];

    NSMutableURLRequest *mRequest;
    if ([aRequest isKindOfClass:[NSMutableURLRequest class]]) {
        mRequest = (NSMutableURLRequest *)aRequest;
    } else {
        mRequest = [aRequest mutableCopy];
        [mRequest setAllHTTPHeaderFields:self.defaultHeaders];
    }

    self.baseURLFallback = [mRequest.URL baseURL];
    if (!baseURLFallback) {
        self.baseURLFallback = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/", mRequest.URL.scheme, mRequest.URL.host]];
    }

    self.currentRequest = mRequest;

    // Controllers can set useWebViewLoading for pages that are ajax powered and do not play nice with AFNetworking requests.
    // Webstats is a good example.
    if (useWebViewLoading) {
        [[self webView] loadRequest:mRequest];
        return;
    }

    self.currentHTTPRequestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:mRequest];

    __weak WPWebView *wpWebView = self;
    [currentHTTPRequestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Check for a redirect.  Make sure the current URL reflects any redirects.
        NSURL *currURL = [[wpWebView currentRequest] URL];
        NSURL *respURL = [[operation response] URL];
        if (![[currURL absoluteString] isEqualToString:[respURL absoluteString]]) {
            NSMutableURLRequest *mReq = [wpWebView.currentRequest mutableCopy];
            [mReq setURL:respURL];
            wpWebView.currentRequest = mReq;
            wpWebView.baseURLFallback = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/", mReq.URL.scheme, mReq.URL.host]];
        }
        [wpWebView.webView loadData:operation.responseData MIMEType:operation.response.MIMEType textEncodingName:@"utf-8" baseURL:aRequest.URL];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [wpWebView webView:wpWebView.webView didFailLoadWithError:error];
    }];

    [currentHTTPRequestOperation start];
}

- (void)loadPath:(NSString *)path
{
    NSURL *url = [NSURL URLWithString:path];
    if (!url) return;

    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [self loadRequest:req];
}

- (void)reload
{
    if ([self request] && !useWebViewLoading) {
        [self loadRequest:[self request]];
    } else {
        [webView reload];
    }
}

- (void)stopLoading
{
    [self setLoading:NO];

    // Cancel the currentRequest but do not dispose of it. Maybe we want to reload it later.
    if (currentHTTPRequestOperation && currentHTTPRequestOperation.isExecuting) {
        [currentHTTPRequestOperation cancel];
    } else if (webView.isLoading) {
        [webView stopLoading];
    }
}

#pragma mark -
#pragma mark WebView Passthrough Methods

- (BOOL)scalesPageToFit
{
    return [webView scalesPageToFit];
}

- (void)setScalesPageToFit:(BOOL)value
{
    [webView setScalesPageToFit:value];
}

- (BOOL)canGoBack
{
    return [webView canGoBack];
}

- (BOOL)canGoForward
{
    return [webView canGoForward];
}

- (void)goBack
{
    [webView goBack];
}

- (void)goForward
{
    [webView goForward];
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script
{
    return [webView stringByEvaluatingJavaScriptFromString:script];
}

#pragma mark -
#pragma mark WebViewDelegate Methods

- (BOOL)webView:(UIWebView *)webView
        shouldStartLoadWithRequest:(NSURLRequest *)aRequest
        navigationType:(UIWebViewNavigationType)navigationType
{
    // applewebdata:// urls are a problem. Kill that request and substitute a better one. Assumes a GET request.
    if ([@"applewebdata" isEqualToString:aRequest.URL.scheme]) {
        NSString *basepath = [self.baseURLFallback absoluteString];
        basepath = [basepath substringToIndex:[basepath length] - 1]; // remove the trailing slash.
        NSString *path = [NSString stringWithFormat:@"%@%@?%@", basepath, aRequest.URL.path, aRequest.URL.query];

        // Since we are rewriting the request's url we need to retrigger the load so it is handled correctly,
        // but we also need to respect the wishes of a delegate.
        NSMutableURLRequest *modRequest = [aRequest mutableCopy];
        [modRequest setURL:[NSURL URLWithString:path]];

        if (delegate && [delegate respondsToSelector:@selector(wpWebView:shouldStartLoadWithRequest:navigationType:)]) {
            // ask the delegate what it wants to do.
            BOOL should = [delegate wpWebView:self shouldStartLoadWithRequest:modRequest navigationType:navigationType];
            if (should) {
                // YES! Let the loading begin!
                [self performSelector:@selector(loadRequest:) withObject:modRequest afterDelay:0.1];
            } else {
                // NOOP - the delegate does not want the webview to load this request so do nothing now and
                // return NO in a moment.
            }
        } else {
            // No delegate or the it doesn't implement the method so load the modified url and return no.
            [self performSelector:@selector(loadRequest:) withObject:modRequest afterDelay:0.1];
        }
        return NO;
    }

    // If we have a delegate listening to this method, let the delegate decide how to handle it.
    // iFrames can trigger this, so we won't store the request.
    if (delegate && [delegate respondsToSelector:@selector(wpWebView:shouldStartLoadWithRequest:navigationType:)]) {
        return [delegate wpWebView:self shouldStartLoadWithRequest:aRequest navigationType:navigationType];
    }

    // Check reachibility after the delegates have been checked. Delegates may have their own reachibility check and we don't
    // want to conflict.
    if (![[self reachability] isReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return NO;
    }

    // No delegate so do our default action is to just handle the request.
    self.currentRequest = aRequest;
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self setLoading:YES];
    if (delegate && [delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [delegate webViewDidStartLoad:self];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self setLoading:NO];

    if (delegate && [delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [delegate webViewDidFinishLoad:self];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self setLoading:NO];

    // If we have a delegate, let it handle the error.
    if (delegate && [delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [delegate webView:self didFailLoadWithError:error];
        return;
    }
    // No delegate so perform a default action.
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error loading page", nil)
                                                        message:NSLocalizedString(@"There was an error loading the page.", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Retry?", nil), nil];
    [alertView show];
}

#pragma mark -
#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) { // retry button
        [self reload];
    }
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    if (![[self reachability] isReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        [self performSelector:@selector(hideRefreshingState) withObject:nil afterDelay:0.3];
        return;
    }

    if (currentRequest == nil && !simulatingPullToRefresh) {
        // If we pull to refresh when a string or data was loaded then it is the resposibility of the
        // loading object to refresh the content.
        [[NSNotificationCenter defaultCenter] postNotificationName:refreshedWithOutValidRequestNotification object:self userInfo:nil];
        didTriggerRefresh = YES;
        return;
    }

    if (loading) return; //loop breaker.
    didTriggerRefresh = YES;
    [self reload];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
    return NO;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
    return lastWebViewRefreshDate;
}

// provide a way for web apps to show the native pull to refresh loading indicator
- (void)showRefreshingState
{
    simulatingPullToRefresh = YES;
    CGPoint offset = scrollView.contentOffset;
    offset.y = - 65.0f;
    [scrollView setContentOffset:offset];
    [refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    simulatingPullToRefresh = NO;
}

- (void)hideRefreshingState
{
    self.lastWebViewRefreshDate = [NSDate date];
    [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:scrollView];
    didTriggerRefresh = NO;
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    [refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate
{
    [refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

@end
