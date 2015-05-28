#import "WPWebViewController.h"
#import "WordPressAppDelegate.h"
#import "ReachabilityUtils.h"
#import "WPActivityDefaults.h"
#import "NSString+Helpers.h"
#import "UIDevice+Helpers.h"
#import "WPURLRequest.h"
#import "WPUserAgent.h"
#import "WPCookie.h"
#import "Constants.h"
#import "WPError.h"
#import "WordPress-Swift.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

//  Error Codes:
//   -999: Canceled AJAX request
//   102:  Frame load interrupted: canceled wp-login redirect to make the POST
//
static NSInteger const WPWebViewErrorAjaxCancelled         = -999;
static NSInteger const WPWebViewErrorFrameLoadInterrupted  = 102;


#pragma mark ====================================================================================
#pragma mark Private Properties
#pragma mark ====================================================================================

@interface WPWebViewController () <UIWebViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic,   weak) IBOutlet UIWebView                *webView;
@property (nonatomic,   weak) IBOutlet UIProgressView           *progressView;
@property (nonatomic,   weak) IBOutlet UIBarButtonItem          *backButton;
@property (nonatomic,   weak) IBOutlet UIBarButtonItem          *forwardButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem          *optionsButton;
@property (nonatomic, strong) UIRefreshControl                  *refreshControl;
@property (nonatomic, strong) UIPopoverController               *popover;
@property (nonatomic, assign) BOOL                              loading;
@property (nonatomic, assign) BOOL                              needsLogin;

@end


#pragma mark ====================================================================================
#pragma mark WPWebViewController
#pragma mark ====================================================================================

@implementation WPWebViewController

- (void)dealloc
{
    _webView.delegate = nil;
    if (_webView.isLoading) {
        [_webView stopLoading];
    }
}

- (void)viewDidLoad
{
    DDLogMethod();
    [super viewDidLoad];

    NSAssert(self.webView,          @"Missing Outlet!");
    NSAssert(self.progressView,     @"Missing Outlet!");
//    NSAssert(self.backButton,       @"Missing Outlet!");
//    NSAssert(self.forwardButton,    @"Missing Outlet!");
    NSAssert(self.optionsButton,    @"Missing Outlet!");
    
    // Initialize Strings
    self.title                              = NSLocalizedString(@"Loading...", @"");
    self.backButton.accessibilityLabel      = NSLocalizedString(@"Back", @"Spoken accessibility label");
    self.forwardButton.accessibilityLabel   = NSLocalizedString(@"Forward", @"Spoken accessibility label");
    self.optionsButton.accessibilityLabel   = NSLocalizedString(@"Share", @"Spoken accessibility label");

    self.webView.scalesPageToFit            = YES;
    self.refreshControl                     = [[UIRefreshControl alloc] init];
    
    // Refresh Control: Hook Up!
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [self.webView.scrollView addSubview:self.refreshControl];

    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:self.optionsButton forNavigationItem:self.navigationItem];
    
    [self loadWebViewRequest];
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogMethod()
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    DDLogMethod()
    [super viewWillDisappear:animated];
}

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (BOOL)expectsWidePanel
{
    return YES;
}


#pragma mark - Document Helpers

- (NSString *)documentPermalink
{
    NSString *permaLink = self.webView.request.URL.absoluteString;

    // Make sure we are not sharing URL like this: http://en.wordpress.com/reader/mobile/?v=post-16841252-1828
    if ([permaLink rangeOfString:@"wordpress.com/reader/mobile/"].location != NSNotFound) {
        permaLink = WPMobileReaderURL;
    }

    return permaLink;
}

- (NSString *)documentTitle
{
    NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];

    if (title != nil && [[title trim] isEqualToString:@""] == NO) {
        return title;
    }

    return [self documentPermalink] ?: [NSString string];
}


#pragma mark - Helper Methods

- (void)loadWebViewRequest
{
    DDLogMethod()

    if (![ReachabilityUtils isInternetReachable]) {
        [self showNoInternetAlertView];
        return;
    }

    if (!self.needsLogin && self.username && self.password && ![WPCookie hasCookieForURL:self.url andUsername:self.username]) {
        DDLogWarn(@"We have login credentials but no cookie, let's try login first");
        [self retryWithLogin];
        return;
    }
    
    NSURLRequest *request = [self newRequestForWebsite];
    NSAssert(request, @"We should have a valid request here!");
    
    [self.webView loadRequest:request];
}

- (void)retryWithLogin
{
    self.needsLogin = YES;
    [self loadWebViewRequest];
}

- (void)refreshInterface
{
    self.backButton.enabled     = self.webView.canGoBack;
    self.forwardButton.enabled  = self.webView.canGoForward;
    self.optionsButton.enabled  = !self.loading;
    
    if (self.loading) {
        return;
    }
    
    self.title = [self documentTitle];
    
    if (self.refreshControl.refreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (void)applyMobileViewportHackIfNeeded
{
    if (CGRectGetWidth(self.view.frame) >= CGRectGetWidth(self.view.window.bounds)) {
        return;
    }
    
    NSString *js = @"var meta = document.createElement('meta');"
                    "meta.setAttribute( 'name', 'viewport' );"
                    "meta.setAttribute( 'content', 'width = available-width, initial-scale = 1.0, user-scalable = yes' );"
                    "document.getElementsByTagName('head')[0].appendChild(meta)";
    
    [self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)scrollToBottomIfNeeded
{
    if (!self.shouldScrollToBottom) {
        return;
    }
    
    self.shouldScrollToBottom = NO;
    
    UIScrollView *scrollView    = self.webView.scrollView;
    CGPoint bottomOffset        = CGPointMake(0, scrollView.contentSize.height - scrollView.bounds.size.height);
    [scrollView setContentOffset:bottomOffset animated:YES];
}

- (void)showNoInternetAlertView
{
    __typeof(self) __weak weakSelf = self;
    [ReachabilityUtils showAlertNoInternetConnectionWithRetryBlock:^{
        [weakSelf loadWebViewRequest];
    }];
}


#pragma mark - Properties

- (void)setUrl:(NSURL *)theURL
{
    if (_url == theURL) {
        return;
    }
    
    _url = theURL;
    [self loadWebViewRequest];
}


#pragma mark - IBAction Methods

//- (IBAction)goBack
//{
//    if (self.webView.isLoading) {
//        [self.webView stopLoading];
//    }
//    [self.webView goBack];
//}
//
//- (IBAction)goForward
//{
//    if (self.webView.isLoading) {
//        [self.webView stopLoading];
//    }
//    [self.webView goForward];
//}

- (IBAction)reload
{
    if (![ReachabilityUtils isInternetReachable]) {
        [self.refreshControl endRefreshing];
        [self showNoInternetAlertView];
        return;
    }
    
    [self.webView reload];
}

- (IBAction)showLinkOptions
{
    NSString* permaLink             = [self documentPermalink];
    NSString *title                 = [self documentTitle];
    NSMutableArray *activityItems   = [NSMutableArray array];
    
    if (title) {
        [activityItems addObject:title];
    }

    [activityItems addObject:[NSURL URLWithString:permaLink]];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:[WPActivityDefaults defaultActivities]];
    if (title) {
        [activityViewController setValue:title forKey:@"subject"];
    }
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (!completed) {
            return;
        }
        [WPActivityDefaults trackActivityType:activityType];
    };

    if ([UIDevice isPad]) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:self.optionsButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}


#pragma mark - UIPopover Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DDLogInfo(@"%@ Should Start Loading URL: %@", NSStringFromClass([self class]), request.URL.absoluteString);
    
    NSRange loginRange = [request.URL.absoluteString rangeOfString:@"wp-login.php"];
    if (loginRange.location != NSNotFound && !self.needsLogin && self.username && self.password)
    {
        DDLogInfo(@"WP is asking for credentials, let's login first");
        [self retryWithLogin];
        return NO;
    }
    
    self.loading = YES;
    [self refreshInterface];
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
    DDLogInfo(@"%@ Started Loading URL: %@", NSStringFromClass([self class]), aWebView.request.URL);
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogInfo(@"%@ Error Loading URL: %@", NSStringFromClass([self class]), error);
    
    if (error.code != WPWebViewErrorAjaxCancelled && error.code != WPWebViewErrorFrameLoadInterrupted) {
        [WPError showAlertWithTitle:NSLocalizedString(@"Error", nil) message:error.localizedDescription];
    }
    
    self.loading = NO;
    
    [self refreshInterface];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    DDLogInfo(@"%@ Finished Loading URL: %@ :: %d", NSStringFromClass([self class]), aWebView.request.URL);

    self.loading = NO;

    [self refreshInterface];
    [self applyMobileViewportHackIfNeeded];
    [self scrollToBottomIfNeeded];
}


#pragma mark - Requests Helpers

- (NSURLRequest *)newRequestForWebsite
{
    NSString *userAgent = [[WordPressAppDelegate sharedInstance].userAgent currentUserAgent];
    if (!self.needsLogin) {
        return [WPURLRequest requestWithURL:self.url userAgent:userAgent];
    }
    
    NSURL *loginURL = self.wpLoginURL ?: [[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"];
    
    return [WPURLRequest requestForAuthenticationWithURL:loginURL
                                             redirectURL:self.url
                                                username:self.username
                                                password:self.password
                                             bearerToken:self.authToken
                                               userAgent:userAgent];
}

@end
