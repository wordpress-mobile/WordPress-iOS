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
#import "WPFriendFinderViewController.h"
#import "SFHFKeychainUtils.h"
#import "JSONKit.h"
#import "ReachabilityUtils.h"

#ifdef DEBUG
#define kReaderRefreshThreshold 10*60 // 10min
#else
#define kReaderRefreshThreshold (30*60) // 30m
#endif

NSString *const WPReaderViewControllerDisplayedFriendFinder = @"displayed friend finder";

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
- (void)canIHazCookie;

@end


// Empty category allows us to define "private" properties
@interface WPReaderViewController ()

@property (nonatomic, strong) WPReaderDetailViewController *detailViewController; 

@end

@implementation WPReaderViewController
@synthesize url, username, password, detailContentHTML;
@synthesize refreshTimer, iPadNavBar;
@synthesize topicsViewController, detailViewController, friendFinderNudgeView, titleButton;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.refreshTimer = nil;
    self.topicsViewController.delegate = nil;
    self.detailViewController.delegate = nil;
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
        
        self.topicsViewController = [[WPReaderTopicsViewController alloc] initWithNibName:@"WPReaderViewController" bundle:nil];
        self.topicsViewController.delegate = self;
        self.detailViewController = [[WPReaderDetailViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
        self.detailViewController.delegate = self;

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

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView { 
    if (self.panelNavigationController) { 
        [self.panelNavigationController viewControllerWantsToBeFullyVisible:self]; 
    } 
} 

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Reader", "");
        
    self.webView.backgroundColor = [UIColor colorWithHue:0.0 saturation:0.0 brightness:0.95 alpha:1.0];

    [self setLoading:NO];
    self.webView.scalesPageToFit = YES;
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.style.background = '#F2F2F2';"];

    
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
    if (IS_IPAD)
        [self.panelNavigationController setToolbarHidden:NO forViewController:self animated:NO];
    self.panelNavigationController.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [self performSelector:@selector(showFriendFinderNudgeView:) withObject:self afterDelay:3.0];
}


- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillDisappear:animated];
    self.panelNavigationController.delegate = nil;
}

- (void)viewDidUnload
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];  
    [super viewDidUnload];
    
   	[self setRefreshTimer:nil];
//    self.topicsViewController = nil;
//    self.detailViewController = nil;
    self.friendFinderNudgeView = nil;
    self.titleButton = nil;
    [self removeNotifications];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (parent == nil) {
        [self setRefreshTimer:nil];
    }
}

#pragma mark - DetailViewDelegate

- (void)resetView {
    [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.deselectSelectedItem()"];
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
    if (IS_IPAD) {
        nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
		nav.modalPresentationStyle = UIModalPresentationFormSheet;
    }
   
    [self presentModalViewController:nav animated:YES];
}

- (void)topicsController:(WPReaderTopicsViewController *)topicsController didDismissSelectingTopic:(NSString *)topic withTitle:(NSString *)title
{
    [self dismiss];
    if (topic != nil) {
        NSString *javaScriptString = [NSString stringWithFormat:@"Reader2.load_topic('%@');", topic];
        [self.webView stringByEvaluatingJavaScriptFromString:javaScriptString];
        if (IS_IPAD)
            [self.panelNavigationController popToRootViewControllerAnimated:YES];
    }
    if (title != nil){
        [self setTitle:title];
    }
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

    UIBarButtonItem *button = nil;
    if (IS_IPHONE && [[UIButton class] respondsToSelector:@selector(appearance)]) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage imageNamed:@"navbar_read"] forState:UIControlStateNormal];
        // Left this in here for now, not sure if the below is needed for iPad but the if above suggests not
        [btn setImage:[UIImage imageNamed:@"navbar_read"] forState:UIControlStateHighlighted];
        UIImage *backgroundImage = [[UIImage imageNamed:@"navbar_button_bg"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
        [btn setBackgroundImage:backgroundImage forState:UIControlStateNormal];

        backgroundImage = [[UIImage imageNamed:@"navbar_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
        [btn setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
        
        btn.frame = CGRectMake(0.0f, 0.0f, 44.0f, 30.0f);

        [btn addTarget:self action:@selector(showTopicSelector:) forControlEvents:UIControlEventTouchUpInside];
        button = [[UIBarButtonItem alloc] initWithCustomView:btn];
    } else {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks 
                                                               target:self 
                                                               action:@selector(showTopicSelector:)];
    }
    [button setAccessibilityLabel:NSLocalizedString(@"Topics", @"")];
    
    if ([button respondsToSelector:@selector(setTintColor:)]) {
        UIColor *color = [UIColor UIColorFromHex:0x464646];
        button.tintColor = color;
    }
    
    if (IS_IPHONE) {
        [self.navigationItem setRightBarButtonItem:button animated:YES];
    } else {
        titleButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(showTopicSelector:)];
        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spacer.width = 8.0f;
        self.toolbarItems = [NSArray arrayWithObjects:button, spacer, titleButton, nil];
    }
    
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

#pragma mark - Hybrid Methods

- (void)showArticleDetails:(id)item
{
    if(![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }
    
    NSDictionary *article = (NSDictionary *)item;
    [self.panelNavigationController popToViewController:self animated:NO];
    self.detailViewController.currentItem = [article JSONString];
    [self.panelNavigationController pushViewController:self.detailViewController animated:YES];
}

#pragma mark - webView related methods

- (void)setStatusTimer:(NSTimer *)timer
{
    //   [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	if (statusTimer && timer != statusTimer) {
		[statusTimer invalidate];
	}
	statusTimer = timer;
}

- (void)setRefreshTimer:(NSTimer *)timer
{
    //   [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	if (refreshTimer && timer != refreshTimer) {
		[refreshTimer invalidate];
	}
	refreshTimer = timer;
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
    
    NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@&rememberme=forever&redirect_to=%@",
                              [self.username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                              [self.password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                              [self.url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    loginRequest.HTTPBody = [request_body dataUsingEncoding:NSUTF8StringEncoding];
    loginRequest.HTTPMethod = @"POST";
    [loginRequest setValue:[NSString stringWithFormat:@"%d", [request_body length]] forHTTPHeaderField:@"Content-Length"];
    [loginRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:loginRequest delegate:nil];
    [connection start];
    
    
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
    request = [self.webBridge authorizeHybridRequest:request];
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
        url = theURL;
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
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL  ]];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate]; 
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    @autoreleasepool {
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
        [conn start];
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [FileLogger log:@"%@ %@: %@://%@%@", self, NSStringFromSelector(_cmd), [[request URL] scheme], [[request URL] host], [[request URL] path]];
    
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
            // return NO;
        }
    }
    
    if ( ![requestedURL isEqual:self.url] && [requestedURLAbsoluteString rangeOfString:@"wp-login.php"].location == NSNotFound ) {
                
        if ( [requestedURLAbsoluteString rangeOfString:kMobileReaderDetailLegacyURL].location != NSNotFound ) {
            // Detail view is now being handled by showDetailView via hybrid bridge
            return NO;
        } else if ( [requestedURLAbsoluteString rangeOfString:kMobileReaderFPURL].location == NSNotFound
                   && [requestedURLAbsoluteString rangeOfString:kMobileReaderURL].location == NSNotFound ) {
            //When in FP and the user click on an item we should push a new VC into the stack
            WPWebViewController *webViewController = [[WPWebViewController alloc] init];
            webViewController.url = [request URL];
            [self.panelNavigationController popToRootViewControllerAnimated:NO];
            [self.panelNavigationController pushViewController:detailViewController animated:YES];
            return NO;
        }
    }
        
    if( [requestedURLAbsoluteString rangeOfString:kMobileReaderFPURL].location == NSNotFound && [requestedURLAbsoluteString rangeOfString:kMobileReaderURL].location != NSNotFound ){
        [self pingStatsEndpoint:@"home_page"];

    }
    
    if ([requestedURLAbsoluteString rangeOfString:kMobileReaderURL].location != NSNotFound) {
        [self setLoading:YES];
        return YES;
    }
    
    return NO;
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

#pragma mark - Friend Finder Button


- (BOOL) shouldDisplayfriendFinderNudgeView {
    #ifdef DEBUG
    return self.friendFinderNudgeView == nil;
    #endif

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return ![userDefaults boolForKey:WPReaderViewControllerDisplayedFriendFinder] && self.friendFinderNudgeView == nil;
}

- (void) showFriendFinderNudgeView:(id)sender {
    
    if ([self shouldDisplayfriendFinderNudgeView]) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        [userDefaults setBool:YES forKey:WPReaderViewControllerDisplayedFriendFinder];
        [userDefaults synchronize];
        
        CGRect buttonFrame = CGRectMake(0,self.view.frame.size.height,self.view.frame.size.width, 0.f);
        WPFriendFinderNudgeView *nudgeView = [[WPFriendFinderNudgeView alloc] initWithFrame:buttonFrame];
        self.friendFinderNudgeView = nudgeView;
        self.friendFinderNudgeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:self.friendFinderNudgeView];
        
        buttonFrame = self.friendFinderNudgeView.frame;
        CGRect viewFrame = self.webView.frame;        
        buttonFrame.origin.y = viewFrame.size.height - buttonFrame.size.height + 1.f;
        
        [self.friendFinderNudgeView.cancelButton addTarget:self action:@selector(hideFriendFinderNudgeView:) forControlEvents:UIControlEventTouchUpInside];
        [self.friendFinderNudgeView.confirmButton addTarget:self action:@selector(openFriendFinder:) forControlEvents:UIControlEventTouchUpInside];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.friendFinderNudgeView.frame = buttonFrame;
        }];
        
        
    }

}

- (void) hideFriendFinderNudgeView:(id)sender {
    
    if (self.friendFinderNudgeView == nil) {
        return;
    }
    
    CGRect buttonFrame = self.friendFinderNudgeView.frame;
    CGRect viewFrame = self.webView.frame;
    buttonFrame.origin.y = viewFrame.size.height + 1.f;
    [UIView animateWithDuration:0.1 animations:^{
        self.friendFinderNudgeView.frame = buttonFrame;
    } completion:^(BOOL finished) {
        [self.friendFinderNudgeView removeFromSuperview];
        self.friendFinderNudgeView = nil;
    }];
    
}

- (void)openFriendFinder:(id)sender {
    [self hideFriendFinderNudgeView:sender];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.topicsViewController];
    WPFriendFinderViewController *friendFinder = [[WPFriendFinderViewController alloc] initWithNibName:@"WPReaderViewController" bundle:nil];
    [navController pushViewController:friendFinder animated:NO];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:navController animated:YES];
    [friendFinder loadURL:kMobileReaderFFURL];

}

#pragma mark - View Overrides

- (void)setTitle:(NSString *)title {
    
    if ([title isEqualToString:@""])
        title = NSLocalizedString(@"Reader", @"");
    
    [super setTitle: title];
    
    if (IS_IPAD) {
        if (titleButton)
            [titleButton setTitle:title];
    }
}


@end