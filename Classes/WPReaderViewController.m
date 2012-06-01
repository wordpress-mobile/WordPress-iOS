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
#import "SFHFKeychainUtils.h"

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
- (void)refreshWebViewNotification:(NSNotification*)notification;
- (void)refreshWebViewTimer:(NSTimer*)timer;
- (void)refreshWebViewIfNeeded;
- (void)retryWithLogin;
- (void)pingStatsEndpoint:(NSString*)statName;


@end


// Empty category allows us to define "private" properties
@interface WPReaderViewController ()

@property (nonatomic, retain) WPReaderDetailViewController *detailViewController; 

@end

@implementation WPReaderViewController
@synthesize url, username, password, detailContentHTML;
@synthesize refreshTimer, iPadNavBar;
@synthesize topicsViewController, detailViewController;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.url = nil;
    self.username = nil;
    self.password = nil;
    self.detailContentHTML = nil;
    self.refreshTimer = nil;
    self.topicsViewController = nil;
    self.detailViewController = nil;
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.url = [NSURL URLWithString:kMobileReaderURL];
        NSError *error = nil; 
        NSString *wpcom_username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"]; 
        NSString *wpcom_password = [SFHFKeychainUtils getPasswordForUsername:wpcom_username 
                                                              andServiceName:@"WordPress.com" 
                                                                       error:&error];
        if (wpcom_username && wpcom_password) {
            self.username = wpcom_username;
            self.password = wpcom_password;
        }
        
        [self canIHazCookie];
    }
    return self;
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

    self.detailViewController = [[WPReaderDetailViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil]; 
    self.detailViewController.delegate = self;

    
    if (self.url) {
        NSString *loaderPath = [[NSBundle mainBundle] pathForResource:@"loader" ofType:@"html"];
        [self.webView loadHTMLString:[NSString stringWithContentsOfFile:loaderPath encoding:NSUTF8StringEncoding error:nil] baseURL:[NSURL URLWithString:kMobileReaderFakeLoaderURL]];
    }
    

    [self refreshWebView];
    [self addNotifications];

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
    self.detailViewController = nil;
    [self removeNotifications];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation)) && interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown)
        return YES;
    
    return NO;
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (parent == nil) {
        [self setRefreshTimer:nil];
    }
}

#pragma mark - Detail View Controller Delegate Methods

- (id)nextItemForDetailController:(WPReaderDetailViewController *)detailController
{
    NSString *item = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.get_next_item()"];
    NSLog(@"Next: %@", item);
    return item;
}

- (id)previousItemForDetailController:(WPReaderDetailViewController *)detailController
{
    return [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.get_previous_item()"];
}

- (BOOL)detailController:(WPReaderDetailViewController *)detailController hasNextForItem:(id)item
{
    return [[self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.has_next_item()"] isEqualToString:@"true"];
}

- (BOOL)detailController:(WPReaderDetailViewController *)detailController hasPreviousForItem:(id)item
{
    NSString *prev = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.has_previous_item()"];
    return [prev isEqualToString:@"true"];
}

#pragma mark - Topic View Controller Methods
- (void)showTopicSelector:(id)sender
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.topicsViewController];
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
}

- (void)removeNotifications{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
    // fetch the cookie using a NSURLRequest and NSURLConnection
    // when the cookie has been made available the Reader will automatically
    // be authenticated
    
    NSURL *loginURL = [[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"];
    NSMutableURLRequest *loginRequest = [[NSMutableURLRequest alloc] initWithURL:loginURL];
    [loginURL release];
    
    NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@&rememberme=forever&redirect_to=%@",
                              [self.username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                              [self.password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                              [self.url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    loginRequest.HTTPBody = [request_body dataUsingEncoding:NSUTF8StringEncoding];
    loginRequest.HTTPMethod = @"POST";
    [loginRequest setValue:[NSString stringWithFormat:@"%d", [request_body length]] forHTTPHeaderField:@"Content-Length"];
    [loginRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:loginRequest delegate:nil];
    [loginRequest release];
    [connection start];
    [connection release];
    
    
    return NO;
}

- (void)refreshWebView {
    
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
        
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate]; 
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
    request.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    // prefetch the details page        
    self.detailViewController.url = [NSURL URLWithString:kMobileReaderDetailURL];
    // load the topics page
    [self.detailViewController view];
    [self.topicsViewController loadTopicsPage];
    request = [self authorizeHybridRequest:request];
    [self.webView loadRequest:request];
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
            // return NO;
        }
    }
    
    if ( ![requestedURL isEqual:self.url] && [requestedURLAbsoluteString rangeOfString:@"wp-login.php"].location == NSNotFound ) {
                
        if ( [requestedURLAbsoluteString rangeOfString:kMobileReaderDetailURL].location != NSNotFound ) {

            [self.panelNavigationController popToRootViewControllerAnimated:NO];
            NSString *item = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.get_current_item()"];
            self.detailViewController.currentItem = item;
            [self.panelNavigationController pushViewController:detailViewController animated:YES];
                        
            return NO;
        } else if ( [requestedURLAbsoluteString rangeOfString:kMobileReaderFPURL].location == NSNotFound
                   && [requestedURLAbsoluteString rangeOfString:kMobileReaderURL].location == NSNotFound ) {
            //When in FP and the user click on an item we should push a new VC into the stack
            WPWebViewController *webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil]; 
            webViewController.url = [request URL]; 
            [self.panelNavigationController popToRootViewControllerAnimated:NO];
            [self.panelNavigationController pushViewController:detailViewController animated:YES];
            [webViewController release];
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
    
}

@end