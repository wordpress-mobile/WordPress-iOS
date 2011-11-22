//
//  WPReaderViewController.m
//  WordPress
//
//  Created by Danilo Ercoli on 10/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "WPReaderViewController.h"
#import "WPWebViewController.h"
#import "ASIHTTPRequest.h"

#ifdef DEBUG
#define kReaderRefreshThreshold 10*60 // 10min
#else
#define kReaderRefreshThreshold (30*60) // 30m
#endif

@interface WPReaderViewController (Private)
- (void)refreshWebView;
- (void)setLoading:(BOOL)loading;
- (void)removeNotifications;
- (void)addNotifications;
- (void)readerCached:(NSNotification*)notification;
- (void)refreshWebViewNotification:(NSNotification*)notification;
- (void)refreshWebViewTimer:(NSTimer*)timer;
- (void)refreshWebViewIfNeeded;
- (void)retryWithLogin;
- (void)detailedViewFinishSelector:(ASIHTTPRequest *)xmlrpcRequest;
- (void)detailedViewFailSelector:(ASIHTTPRequest *)request;
- (void)pingStatsEndpoint:(NSString*)statName;
@end

@implementation WPReaderViewController
@synthesize url, username, password, detailContentHTML;
@synthesize webView, refreshTimer, lastWebViewRefreshDate, iPadNavBar;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.url = nil;
    self.username = nil;
    self.password = nil;
    self.detailContentHTML = nil;
    self.webView = nil;
    self.refreshTimer = nil;
    self.lastWebViewRefreshDate = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil ];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)] autorelease];
    }
    return self;
}   

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    isLoading = YES;
    [self setLoading:NO];
    self.webView.scalesPageToFit = YES;
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.style.background = '#F2F2F2';"];
    if (self.url) {
        [self refreshWebView];
    }
    [self addNotifications];
    [self setRefreshTimer:[NSTimer timerWithTimeInterval:kReaderRefreshThreshold target:self selector:@selector(refreshWebViewTimer:) userInfo:nil repeats:YES]];
	[[NSRunLoop currentRunLoop] addTimer:[self refreshTimer] forMode:NSDefaultRunLoopMode];
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillAppear:animated];    
}

- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];  
   	[self setRefreshTimer:nil];
    self.webView.delegate = nil;
    self.webView = nil;
    [self removeNotifications];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation)) && interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown)
        return YES;
    
    return NO;
}

#pragma mark - notifications related methods
- (void)addNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWebViewNotification:) name:@"ApplicationDidBecomeActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readerCached:) name:@"ReaderCached" object:nil];
}

- (void)removeNotifications{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)readerCached:(NSNotification*)notification {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.detailContentHTML = nil;
}

- (void)refreshWebViewNotification:(NSNotification*)notification {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self refreshWebViewIfNeeded];
}

- (void)refreshWebViewTimer:(NSTimer*)timer {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self refreshWebViewIfNeeded];
}

- (void)refreshWebViewIfNeeded {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    //check the expire time and refresh the webview
    if ( ! webView.loading ) {
        if( fabs( [self.lastWebViewRefreshDate timeIntervalSinceNow] ) > kReaderRefreshThreshold ) //30minutes 
            [self refreshWebView];
    }
}

#pragma mark - webView related methods

- (void)setStatusTimer:(NSTimer *)timer
{
    //   [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	if (statusTimer && timer != statusTimer) {
		[statusTimer invalidate];
		[statusTimer release];
	}
	statusTimer = [timer retain];
}

- (void)setRefreshTimer:(NSTimer *)timer
{
    //   [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	if (refreshTimer && timer != refreshTimer) {
		[refreshTimer invalidate];
		[refreshTimer release];
	}
	refreshTimer = [timer retain];
}

- (void)loadURL:(NSURL *)webURL {
    
}

- (bool)canIHazCookie {
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:kMobileReaderURL]];
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:@"wordpress_logged_in"]) {
            return YES;
        }
    }
    return NO;
}

- (void)refreshWebView {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
    if (!needsLogin && self.username && self.password && ![self canIHazCookie]) {
        WPFLog(@"We have login credentials but no cookie, let's try login first");
        [self retryWithLogin];
        return;
    }
    
    NSURL *webURL;
    if (needsLogin)
        webURL = [[[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"] autorelease];
    else
        webURL = self.url;
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate]; 
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL];
    request.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    if (needsLogin) {
        NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=%@",
                                  [self.username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  [self.password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  [[self.url absoluteString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [request setURL:[[[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"] autorelease]];
        [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"%d", [request_body length]] forHTTPHeaderField:@"Content-Length"];
        [request addValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setHTTPMethod:@"POST"];
    }
    NSString *readerPath = [appDelegate readerCachePath];
    if (!needsLogin && [self.url.absoluteString isEqualToString:kMobileReaderURL] && [[NSFileManager defaultManager] fileExistsAtPath:readerPath]) {
        [self.webView loadHTMLString:[NSString stringWithContentsOfFile:readerPath encoding:NSUTF8StringEncoding error:nil] baseURL:self.url];
    } else {
        [self.webView loadRequest:request];         
    }
    self.lastWebViewRefreshDate = [NSDate date];    
}

- (void)retryWithLogin {
    needsLogin = YES;
    [self refreshWebView];    
}

- (void)setUrl:(NSURL *)theURL {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    if (url != theURL) {
        [url release];
        url = [theURL retain];
        if (url && self.webView) {
            [self refreshWebView];
        }
    }
}

- (void)setLoading:(BOOL)loading {
    if (isLoading == loading)
        return;

    if (loading) {
        UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [spinner setCenter:customView.center];
        [customView addSubview:spinner];
        
        [spinner startAnimating];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customView];
        
        [spinner release];
        [customView release];
    } else {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload)] autorelease];
    }
    
    if (!loading) {
        if (DeviceIsPad()) {
            [iPadNavBar.topItem setTitle:[webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
        }
        else {
            if (![[webView stringByEvaluatingJavaScriptFromString:@"document.title"] isEqualToString: @""]) 
                self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
            else
                self.navigationItem.title = @"Read";
        }
            
    }
    
    isLoading = loading;
}

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)reload {        
    NSString *requestedURLAbsoluteString = [[self.webView.request  URL] absoluteString];
    if( [requestedURLAbsoluteString rangeOfString:kMobileReaderURL].location != NSNotFound ) {
        [self pingStatsEndpoint:@"home_page_refresh"];
    }
    if ([requestedURLAbsoluteString length] == 0)
        [self refreshWebView];
    else
        [webView reload];
}

- (void)pingStatsEndpoint:(NSString*)statName {
    int x = arc4random();
    NSString *statsURL = [NSString stringWithFormat:@"%@%@%@%@%d" , kMobileReaderURL, @"?template=stats&stats_name=", statName, @"&rnd=", x];
    NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL  ]] autorelease];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate]; 
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    [[[NSURLConnection alloc] initWithRequest:request delegate:nil] autorelease];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [FileLogger log:@"%@ %@: %@", self, NSStringFromSelector(_cmd), [[request URL] absoluteString]];
    
    NSURL *requestedURL = [request URL];
    NSString *requestedURLAbsoluteString = [requestedURL absoluteString];
    
    if (!needsLogin && [requestedURLAbsoluteString rangeOfString:@"wp-login.php"].location != NSNotFound) {
        if (self.username && self.password) {
            WPFLog(@"WP is asking for credentials, let's login first");
            [self retryWithLogin];
            return NO;
        }
    }
    
    if ( ![requestedURL isEqual:self.url] && [requestedURLAbsoluteString rangeOfString:@"wp-login.php"].location == NSNotFound ) {
                
        if ( [requestedURLAbsoluteString rangeOfString:kMobileReaderDetailURL].location != NSNotFound ) {
            //The user tapped an item in the posts list
            WPWebViewController *detailViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil]; 
            if( self.detailContentHTML ) 
                detailViewController.detailHTML = self.detailContentHTML;
            else
                detailViewController.url = [request URL]; 

            detailViewController.detailContent = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.last_selected_item;"];
            detailViewController.readerAllItems = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.get_loaded_items();"];
            detailViewController.isRefreshButtonEnabled = NO;
            [self.navigationController pushViewController:detailViewController animated:YES];
            [detailViewController release];
            
            return NO;
        } else if ( [requestedURLAbsoluteString rangeOfString:kMobileReaderFPURL].location == NSNotFound
                   && [requestedURLAbsoluteString rangeOfString:kMobileReaderURL].location == NSNotFound ) {
            //When in FP and the user click on an item we should push a new VC into the stack
            WPWebViewController *detailViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil]; 
            detailViewController.url = [request URL]; 
            [self.navigationController pushViewController:detailViewController animated:YES];
            [detailViewController release];
            return NO;
        }
    }
    
    if( [requestedURLAbsoluteString rangeOfString:kMobileReaderFPURL].location == NSNotFound && [requestedURLAbsoluteString rangeOfString:kMobileReaderURL].location != NSNotFound )
        [self pingStatsEndpoint:@"home_page"];
    
    [self setLoading:YES];        
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [FileLogger log:@"%@ %@: %@", self, NSStringFromSelector(_cmd), error];
    // -999: Canceled AJAX request
    // 102:  Frame load interrupted: canceled wp-login redirect to make the POST
    if (isLoading && ([error code] != -999) && [error code] != 102)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenWebPageFailed" object:error userInfo:nil];
    [self setLoading:NO];
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView {
    [FileLogger log:@"%@ %@%@", self, NSStringFromSelector(_cmd), aWebView.request.URL];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self setLoading:NO];
    
    //finished to load the Reader Home page, start a new call to get the detailView HTML
    if ( ! self.detailContentHTML ) {
        ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:kMobileReaderDetailURL]];
        [request setRequestMethod:@"GET"];
        [request setShouldPresentCredentialsBeforeChallenge:NO];
        [request setShouldPresentAuthenticationDialog:NO];
        [request setUseKeychainPersistence:NO];
        [request setValidatesSecureCertificate:NO];
        [request setTimeOutSeconds:30];
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];        
        [request addRequestHeader:@"User-Agent" value:[appDelegate applicationUserAgent]];
        [request addRequestHeader:@"Content-Type" value:@"text/xml"];
        [request addRequestHeader:@"Accept" value:@"*/*"];
        
        [request setDidFinishSelector:@selector(detailedViewFinishSelector:)];
        [request setDidFailSelector:@selector(detailedViewFailSelector:)];
        [request setDelegate:self];
        
        [request startAsynchronous];
        [request release];
    }
}


- (void)detailedViewFinishSelector:(ASIHTTPRequest *)request
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.detailContentHTML = [request responseString];
    //NSLog(@"%@", self.detailContentHTML);
}

- (void)detailedViewFailSelector:(ASIHTTPRequest *)request {
	NSError *error = [request error];
	[FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), error];
    self.detailContentHTML = nil;
}

@end