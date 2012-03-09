//
//  WPReaderViewController.m
//  WordPress
//
//  Created by Danilo Ercoli on 10/10/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "WPReaderViewController.h"
#import "WPWebViewController.h"
#import "WordPressAppDelegate.h"

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
- (void)pingStatsEndpoint:(NSString*)statName;
@end

@implementation WPReaderViewController
@synthesize url, username, password, detailContentHTML;
@synthesize refreshTimer, iPadNavBar;
@synthesize topicsViewController;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.url = nil;
    self.username = nil;
    self.password = nil;
    self.detailContentHTML = nil;
    self.refreshTimer = nil;
    self.topicsViewController = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    WPFLogMethod();
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
        
    self.webView.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.95 alpha:1.0];

    [self setLoading:NO];
    self.webView.scalesPageToFit = YES;
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.style.background = '#F2F2F2';"];

    self.topicsViewController = [[[WPReaderTopicsViewController alloc] initWithNibName:@"WPReaderViewController" bundle:nil] autorelease];
    self.topicsViewController.delegate = self;
    
    if (self.url) {
        NSString *loaderPath = [[NSBundle mainBundle] pathForResource:@"loader" ofType:@"html"];
        [self.webView loadHTMLString:[NSString stringWithContentsOfFile:loaderPath encoding:NSUTF8StringEncoding error:nil] baseURL:[NSURL URLWithString:kMobileReaderFakeLoaderURL]];
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
    self.topicsViewController = nil;
    [self removeNotifications];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation)) && interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown)
        return YES;
    
    return NO;
}

#pragma mark - Topic View Controller Methods
- (void)showTopicSelector:(id)sender
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.topicsViewController];
    NSLog(@"What's going on? %@ %@", self.topicsViewController.webView, self.topicsViewController.webView.superview);
    [self presentModalViewController:nav animated:YES];
    [nav release];
}

- (void)topicsController:(WPReaderTopicsViewController *)topicsController didDismissSelectingTopic:(NSString *)topic withTitle:(NSString *)title
{
    if (topic != nil) {
        NSString *javaScriptString = [NSString stringWithFormat:@"Reader2.load_topic('%@');", topic];
        [self.webView stringByEvaluatingJavaScriptFromString:javaScriptString];
    }
    if (title != nil){
        [self setTitle:title];
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)setSelectedTopic:(NSString *)topicId;
{
    [FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), topicId];
    [self.topicsViewController setSelectedTopic:topicId];
    [self setTitle:[self.topicsViewController selectedTopicTitle]];
}

- (void)setupTopics
{
    [self.topicsViewController view];
    [self.topicsViewController loadTopicsPage];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"list"] style:UIBarButtonItemStyleBordered target:self action:@selector(showTopicSelector:)];
    [self.navigationItem setRightBarButtonItem:button animated:YES];
    [button release];
    
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
    if ( ! self.webView.loading ) {
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
                                  [self.url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [request setURL:[[[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"] autorelease]];
        [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"%d", [request_body length]] forHTTPHeaderField:@"Content-Length"];
        [request addValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setHTTPMethod:@"POST"];
    } else {
        [self.topicsViewController loadTopicsPage];
    }
    request = [self authorizeHybridRequest:request];
    NSString *readerPath = [appDelegate readerCachePath];
    if (!needsLogin && [self.url.absoluteString isEqualToString:[WPWebAppViewController authorizeHybridURL:[NSURL URLWithString:kMobileReaderURL]].absoluteString] && [[NSFileManager defaultManager] fileExistsAtPath:readerPath]) {
        [self.webView loadHTMLString:[NSString stringWithContentsOfFile:readerPath encoding:NSUTF8StringEncoding error:nil] baseURL:self.url];
    } else {
        [self.webView loadRequest:request];
    }
    [self setupTopics];

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
        [self.webView reload];
}

- (void)pingStatsEndpoint:(NSString*)statName {
    int x = arc4random();
    NSString *statsURL = [NSString stringWithFormat:@"%@%@%@%@%d" , kMobileReaderURL, @"&template=stats&stats_name=", statName, @"&rnd=", x];
    NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL  ]] autorelease];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate]; 
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    [[[NSURLConnection alloc] initWithRequest:request delegate:nil] autorelease];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [FileLogger log:@"%@ %@: %@", self, NSStringFromSelector(_cmd), [[request URL] absoluteString]];
    
    NSURL *requestedURL = [request URL];
    NSString *requestedURLAbsoluteString = [requestedURL absoluteString];
    if ([requestedURLAbsoluteString isEqualToString:kMobileReaderFakeLoaderURL]) {
        // Local loader
        return YES;
    }
    
    //  check if it's being handled by the hybrid bridge  
    if([super webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType] == NO){
        return NO;
    }
    
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
    
    if( [requestedURLAbsoluteString rangeOfString:kMobileReaderFPURL].location == NSNotFound && [requestedURLAbsoluteString rangeOfString:kMobileReaderURL].location != NSNotFound ){
        [self pingStatsEndpoint:@"home_page"];

    }
    
    [self setLoading:YES];        
    return YES;
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [FileLogger log:@"%@ %@: %@", self, NSStringFromSelector(_cmd), error];
    // -999: Canceled AJAX request
    // 102:  Frame load interrupted: canceled wp-login redirect to make the POST
    if (self.loading && ([error code] != -999) && [error code] != 102)
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenWebPageFailed" object:error userInfo:nil];
    self.loading = NO;
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView {
    [FileLogger log:@"%@ %@%@", self, NSStringFromSelector(_cmd), aWebView.request.URL];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self setLoading:NO];
    
    NSString *wasLocal = [aWebView stringByEvaluatingJavaScriptFromString:@"document.isLocalLoader"];
    if ([wasLocal isEqualToString:@"true"]) {
        [self refreshWebView];
        return;
    }
    
    //finished to load the Reader Home page, start a new call to get the detailView HTML
    if ( ! self.detailContentHTML ) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[kMobileReaderDetailURL stringByAppendingFormat:@"&wp_hybrid_auth_token=%@", self.hybridAuthToken]]];
        [request setHTTPMethod:@"GET"];
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
        [request addValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
        [request addValue:@"*/*" forHTTPHeaderField:@"Accept"];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            self.detailContentHTML = responseObject;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), error];
            self.detailContentHTML = nil;
        }];

        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [queue addOperation:operation];

        [operation release];
        [queue release];
    }
}

@end