//
//  WPWebView.m
//
//  Created by Eric Johnson on 5/23/12.
//

#import "WPWebView.h"
#import "Reachability.h"
#import "AFHTTPRequestOperation.h"

NSString *refreshedWithOutValidRequestNotification = @"refreshedWithOutValidRequestNotification";

@interface WPWebView ()

@property (strong, nonatomic) EGORefreshTableHeaderView *refreshHeaderView;
@property (strong, nonatomic) NSMutableDictionary *defaultHeaders;
@property (strong, nonatomic) NSDate *lastWebViewRefreshDate;
@property (strong, nonatomic) AFHTTPRequestOperation *currentRequest;
@property (strong, nonatomic) Reachability *reachability;
@property (strong, nonatomic) UIView *loadingView;
@property (strong, nonatomic) UILabel *loadingLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityView;
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIScrollView *scrollView;

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
@synthesize currentRequest;
@synthesize reachability;
@synthesize loadingView;
@synthesize loadingLabel;
@synthesize activityView;
@synthesize webView;
@synthesize scrollView;

- (void)dealloc {
    self.delegate = nil;
    webView.delegate = nil;
    self.webView = nil;
    
    self.refreshHeaderView = nil;
    self.defaultHeaders = nil;
    self.lastWebViewRefreshDate = nil;
    self.currentRequest = nil;
    self.reachability = nil;
    self.loadingView = nil;
    self.loadingLabel = nil;
    self.activityView = nil;
    self.webView = nil;
    self.scrollView = nil;
    
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupSubviews];
        [self setupHeaders];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
        [self setupHeaders];
    }
    return self;
}


#pragma mark -
#pragma mark Drawing Methods

- (void)setupHeaders {
    self.defaultHeaders = [NSMutableDictionary dictionary];
    
    // Accept-Encoding HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
	[self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
	
	// Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
	NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
	[self setDefaultHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes]];
    
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    [self setDefaultHeader:@"User-Agent" value:userAgent];
}

- (void)setupSubviews {
    
    CGFloat fontSize = 14.0;
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat width = 0.0;
    CGFloat height = 0.0;
    CGFloat padding = 5.0;
    
    CGRect frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    
    // WebView
    self.webView = [[[UIWebView alloc] initWithFrame:frame] autorelease];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.hidden = YES; // Hidden until content is loaded.
    webView.scalesPageToFit = YES;
    webView.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.95 alpha:1.0];
    [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.background = '#F2F2F2';"];
    
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
		self.refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - scrollView.bounds.size.height, scrollView.frame.size.width, scrollView.bounds.size.height)];
		refreshHeaderView.delegate = self;
		[scrollView addSubview:refreshHeaderView];
	}
    self.lastWebViewRefreshDate = [NSDate date];
	//  update the last update date
	[refreshHeaderView refreshLastUpdatedDate];
    
    
    // Spinner
    self.activityView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    activityView.hidesWhenStopped = NO;
    [activityView startAnimating];
    CGRect activityFrame = activityView.frame;
    
    
    // Build and configure the loadingLabel
    NSString *loadingStr = NSLocalizedString(@"Loading...", nil);
    CGSize size = [loadingStr sizeWithFont:[UIFont systemFontOfSize:fontSize]];

    x = activityFrame.size.width + padding;
    y = (activityFrame.size.height - size.height) / 2;
    
    frame = CGRectMake(x, y, size.width, size.height);
    self.loadingLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
    loadingLabel.font = [UIFont systemFontOfSize:fontSize];
    loadingLabel.textColor = [UIColor grayColor];
    loadingLabel.text = loadingStr;
    loadingLabel.backgroundColor = [UIColor clearColor];
    
    width = activityFrame.size.width + padding + size.width;
    height = activityFrame.size.height;
    
    // Reposition the activityView below the label if width is an issue.    
    if (width > self.frame.size.width ) {
        width = MAX(size.width, activityFrame.size.width);
        height = size.height + activityFrame.size.height + padding;
        
        frame = CGRectMake(0.0, 0.0, size.width, size.height);
        [loadingLabel setFrame:frame];
        
        activityFrame.origin.x = (size.width - activityFrame.size.width) / 2;
        activityFrame.origin.y = size.height + padding;
        [activityView setFrame:activityFrame];
    }
    
    // Create and config the loadingView
    x = (self.frame.size.width - width) / 2;
    y = (self.frame.size.height - height) / 2;

    self.loadingView = [[[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)] autorelease];
    loadingView.backgroundColor = [UIColor clearColor];
    loadingView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin & UIViewAutoresizingFlexibleBottomMargin & 
                                    UIViewAutoresizingFlexibleLeftMargin & UIViewAutoresizingFlexibleRightMargin;
    loadingView.hidden = YES; // Don't show until we start loading something.
    
    [loadingView addSubview:loadingLabel];
    [loadingView addSubview:activityView];
    [self addSubview:loadingView];
}


#pragma mark -
#pragma mark Instance Methods

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
	[defaultHeaders setValue:value forKey:header];
}

- (Reachability *)reachability {
    // lazy load.
    if (!reachability) {
        self.reachability = [Reachability reachabilityForInternetConnection];
    }
    return reachability;
}

- (NSURLRequest *)request {
    if (currentRequest) {
        return currentRequest.request;
    }
    return nil;
}

- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
                                              otherButtonTitles:NSLocalizedString(@"Retry?", nil), nil];
    [alertView show];
    [alertView release];
}

- (void)setCurrentRequest:(AFHTTPRequestOperation *)newCurrentRequest {
    if (currentRequest){
        if(currentRequest.isExecuting) {
            [currentRequest cancel];
        }
        [currentRequest release]; currentRequest = nil;
    }
    currentRequest = [newCurrentRequest retain];
}


#pragma mark -
#pragma Loading Methods

- (BOOL)isLoading {
    return loading;
}

- (void)setLoading:(BOOL)value {
    loading = value;

    // Don't hide the webview if we used the pull to refresh mechanism.
    if (pulledToRefresh) return;
    
    webView.hidden = loading;
    loadingView.hidden = !loading;
}

- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)encodingName baseURL:(NSURL *)baseURL {
    self.currentRequest = nil;
    [self setLoading:YES];
    [webView loadData:data MIMEType:MIMEType textEncodingName:encodingName baseURL:baseURL];
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    self.currentRequest = nil;
    [self setLoading:YES];
    [webView loadHTMLString:string baseURL:baseURL];
}

- (void)loadRequest:(NSURLRequest *)aRequest {
    if (loading) {
        [self stopLoading];
    }

    if (![[self reachability] isReachable]) {
        [self showAlertWithTitle:NSLocalizedString(@"Network Unavailable", nil) 
                      andMessage:NSLocalizedString(@"Please check your device's network connection.", nil)];
        return;
    }
    
    [self setLoading:YES];
    
    NSMutableURLRequest *mRequest = [[NSMutableURLRequest alloc] initWithURL:aRequest.URL 
                                                        cachePolicy:aRequest.cachePolicy 
                                                    timeoutInterval:aRequest.timeoutInterval];
    [mRequest setAllHTTPHeaderFields:self.defaultHeaders];
    
    // here's where the magic happens.
    NSURL *baseURL = [mRequest.URL baseURL];
    
    self.currentRequest = [[[AFHTTPRequestOperation alloc] initWithRequest:mRequest] autorelease];
    
    [currentRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [webView loadData:operation.responseData MIMEType:operation.response.MIMEType textEncodingName:@"utf-8" baseURL:baseURL];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
NSLog(@"Error!");
        [self webView:webView didFailLoadWithError:error];
        
    }];
    
    [currentRequest start];
}

- (void)loadPath:(NSString *)path {
    NSURL *url = [NSURL URLWithString:path];
    if (!url) return;
    
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [self loadRequest:req];
}

- (void)reload {
    if ([self request]) {
        [self loadRequest:[self request]];
    } else {
        [webView reload];
    }
}

- (void)stopLoading {
    [self setLoading:NO];
    
    // Cancel the currentRequest but do not dispose of it. Maybe we want to reload it later.
    if (currentRequest && currentRequest.isExecuting) {
        [currentRequest cancel];
    } else if (webView.isLoading) {
        [webView stopLoading];
    }
}


#pragma mark -
#pragma mark WebView Passthrough Methods

- (BOOL)scalesPageToFit {
    return [webView scalesPageToFit];
}

- (void)setScalesPageToFit:(BOOL)value {
    [webView setScalesPageToFit:value];
}

- (BOOL)canGoBack {
    return [webView canGoBack];
}

- (BOOL)canGoForward {
    return [webView canGoForward];
}

- (void)goBack {
    [webView goBack];
}

- (void)goForward {
    [webView goForward];
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
    return [webView stringByEvaluatingJavaScriptFromString:script];
}


#pragma mark - 
#pragma mark WebViewDelegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)aRequest navigationType:(UIWebViewNavigationType)navigationType {
    // If we have a delegate listening to this method, let the delegate decide how to handle it.
    if (delegate && [delegate respondsToSelector:@selector(wpWebView:shouldStartLoadWithRequest:navigationType:)]) {
        return [delegate wpWebView:self shouldStartLoadWithRequest:aRequest navigationType:navigationType];
    }
    
    if (![[self reachability] isReachable]) {
        [self showAlertWithTitle:NSLocalizedString(@"Network Unavailable", nil) 
                      andMessage:NSLocalizedString(@"Please check your device's network connection.", nil)];
        return NO;
    }
    // No delegate so do our default action is to just handle the request.
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self setLoading:YES];
    if (delegate && [delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [delegate webViewDidStartLoad:self];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    pulledToRefresh = NO;
    [self stopLoading];
    self.lastWebViewRefreshDate = [NSDate date];
    [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:(UIScrollView * )scrollView];
    
    if (delegate && [delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [delegate webViewDidFinishLoad:self];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    pulledToRefresh = NO;
    [self stopLoading];
    self.lastWebViewRefreshDate = [NSDate date];
    [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:(UIScrollView * )scrollView];
    
    // If we have a delegate, let it handle the error.
    if (delegate && [delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [delegate webView:self didFailLoadWithError:error];
        return;
    }
    
    // No delegate so perform a default action.
    NSString *message = NSLocalizedString(@"There was an error loading the page.", nil);
//    message = [message stringByAppendingFormat:@"\n%@",[error description]];
    [self showAlertWithTitle:NSLocalizedString(@"Error loading page", nil) andMessage:message];
}


#pragma mark -
#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // retry button
        [self reload];
    }
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {
    pulledToRefresh = YES;
    
    if (currentRequest == nil) {
        // If we pull to refresh when a string or data was loaded then it is the resposibility of the
        // loading object to refresh the content.
        [[NSNotificationCenter defaultCenter] postNotificationName:refreshedWithOutValidRequestNotification object:self userInfo:nil];
        return;
    }

    [self reload];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
	return loading;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view {
	return lastWebViewRefreshDate;
}

// provide a way for web apps to show the native pull to refresh loading indicator
- (void)showRefreshingState {
    CGPoint offset = scrollView.contentOffset;
    offset.y = - 65.0f;
    [scrollView setContentOffset:offset];
    [refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
	[refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate {
	[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}


@end
