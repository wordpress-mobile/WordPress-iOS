#import "WPWebViewController.h"
#import "WordPressAppDelegate.h"
#import "ReachabilityUtils.h"
#import "WPActivityDefaults.h"
#import "WPUserAgent.h"
#import "Constants.h"
#import "WPError.h"
#import "WPStyleGuide+WebView.h"
#import <WordPressUI/WordPressUI.h>
#import <WordPressShared/UIDevice+Helpers.h>
#import "WordPress-Swift.h"

@import Gridicons;


#pragma mark - Constants

static NSInteger const WPWebViewErrorAjaxCancelled          = -999;
static NSInteger const WPWebViewErrorFrameLoadInterrupted   = 102;

static CGFloat const WPWebViewToolbarShownConstant          = 0.0;
static CGFloat const WPWebViewToolbarHiddenConstant         = -44.0;
static CGFloat const WPWebViewAnimationShortDuration        = 0.1;

static NSString *const WPWebViewWebKitErrorDomain = @"WebKitErrorDomain";
static NSInteger const WPWebViewErrorPluginHandledLoad = 204;

#pragma mark - Private Properties

@interface WPWebViewController () <UIWebViewDelegate>

@property (nonatomic,   weak) IBOutlet UIWebView                *webView;
@property (nonatomic,   weak) IBOutlet WebProgressView          *progressView;
@property (nonatomic, strong) UIBarButtonItem                   *dismissButton;

@property (nonatomic,   weak) IBOutlet UIToolbar                *toolbar;
@property (nonatomic,   weak) IBOutlet UIBarButtonItem          *backButton;
@property (nonatomic,   weak) IBOutlet UIBarButtonItem          *forwardButton;
@property (nonatomic,   weak) IBOutlet NSLayoutConstraint       *toolbarBottomConstraint;

@property (nonatomic, strong) NavigationTitleView               *titleView;
@property (nonatomic, copy)   NSString                          *customTitle;
@property (nonatomic, assign) BOOL                              loading;
@property (nonatomic, assign) BOOL                              needsLogin;
@property (nonatomic, strong) id                                reachabilityObserver;

@property (nonatomic, weak) id<WebNavigationDelegate> navigationDelegate;

@end


#pragma mark - WPWebViewController

@implementation WPWebViewController

- (void)dealloc
{
    [self stopWaitingForConnectionRestored];
    
    _webView.delegate = nil;
    if (_webView.isLoading) {
        [_webView stopLoading];
    }
}

- (instancetype)initWithConfiguration:(WebViewControllerConfiguration *)configuration
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _url = configuration.url;
        _optionsButton = configuration.optionsButton;
        _secureInteraction = configuration.secureInteraction;
        _addsWPComReferrer = configuration.addsWPComReferrer;
        _addsHideMasterbarParameters = configuration.addsHideMasterbarParameters;
        _customTitle = configuration.customTitle;
        _authenticator = configuration.authenticator;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSAssert(_webView,                 @"Missing Outlet!");
    NSAssert(_progressView,            @"Missing Outlet!");

    NSAssert(_toolbar,                 @"Missing Outlet!");
    NSAssert(_backButton,              @"Missing Outlet!");
    NSAssert(_forwardButton,           @"Missing Outlet!");
    NSAssert(_toolbarBottomConstraint, @"Missing Outlet!");
    
    // TitleView
    self.titleView                          = [NavigationTitleView new];
    self.titleView.titleLabel.text          = NSLocalizedString(@"Loading...", @"Loading. Verb");
    self.titleView.subtitleLabel.text       = self.url.host;

    if (self.customTitle != nil) {
        self.title = self.customTitle;
    } else {
        self.navigationItem.titleView = self.titleView;
    }
    
    // Buttons
    if (!self.optionsButton) {
        self.optionsButton = [[UIBarButtonItem alloc] initWithImage:[Gridicon iconOfType:GridiconTypeShareIOS] style:UIBarButtonItemStylePlain target:self action:@selector(showLinkOptions)];

        self.optionsButton.accessibilityLabel   = NSLocalizedString(@"Share",   @"Spoken accessibility label");
    }

    self.dismissButton = [[UIBarButtonItem alloc] initWithImage:[Gridicon iconOfType:GridiconTypeCross] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];

    self.dismissButton.accessibilityLabel   = NSLocalizedString(@"Dismiss", @"Dismiss a view. Verb");
    self.backButton.accessibilityLabel      = NSLocalizedString(@"Back",    @"Previous web page");
    self.forwardButton.accessibilityLabel   = NSLocalizedString(@"Forward", @"Next web page");
    
    self.backButton.image                   = [[Gridicon iconOfType:GridiconTypeChevronLeft] imageFlippedForRightToLeftLayoutDirection];
    self.forwardButton.image                = [[Gridicon iconOfType:GridiconTypeChevronRight] imageFlippedForRightToLeftLayoutDirection];

    // Toolbar: Hidden by default!
    self.toolbar.barTintColor               = [UIColor whiteColor];
    self.backButton.tintColor               = [WPStyleGuide greyLighten10];
    self.forwardButton.tintColor            = [WPStyleGuide greyLighten10];
    self.toolbarBottomConstraint.constant   = WPWebViewToolbarHiddenConstant;
    
    // WebView
    self.webView.scalesPageToFit            = YES;
    
    // Share
    if (!self.secureInteraction) {
        self.navigationItem.rightBarButtonItem  = self.optionsButton;
    }

    // Fire away!
    [self applyModalStyleIfNeeded];
    [self loadWebViewRequest];

    if (UIAccessibilityIsBoldTextEnabled()) {
        self.navigationController.navigationBar.tintColor = [WPStyleGuide greyLighten10];
    }
}

- (void)applyModalStyleIfNeeded
{
    // Proceed only if this Modal, and it's the only view in the stack.
    // We're not changing the NavigationBar style, if we're sharing it with someone else!
    if (self.presentingViewController == nil || self.navigationController.viewControllers.count > 1) {
        return;
    }
    
    UIImage *navBackgroundImage             = [UIImage imageWithColor:[WPStyleGuide webViewModalNavigationBarBackground]];
    UIImage *navShadowImage                 = [UIImage imageWithColor:[WPStyleGuide webViewModalNavigationBarShadow]];
    
    UINavigationBar *navigationBar          = self.navigationController.navigationBar;
    navigationBar.shadowImage               = navShadowImage;
    navigationBar.barStyle                  = UIBarStyleDefault;
    [navigationBar setBackgroundImage:navBackgroundImage forBarMetrics:UIBarMetricsDefault];
    
    self.titleView.titleLabel.textColor     = [WPStyleGuide darkGrey];
    self.titleView.subtitleLabel.textColor  = [WPStyleGuide grey];
    
    self.dismissButton.tintColor            = [WPStyleGuide greyLighten10];
    self.optionsButton.tintColor            = [WPStyleGuide greyLighten10];

    self.navigationItem.leftBarButtonItem   = self.dismissButton;
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
    if ([ReachabilityUtils alertIsShowing]) {
        [self dismissViewControllerAnimated:false completion:nil];
    }
    
    if (self.authenticator == nil) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
        [self loadRequest:request];
        return;
    }
    id<CookieJar> cookieJar = (id<CookieJar>)[NSHTTPCookieStorage sharedHTTPCookieStorage];
    [self.authenticator requestWithUrl:self.url
                             cookieJar:cookieJar
                            completion:^(NSURLRequest * _Nonnull request) {
                                [self loadRequest:request];
                            }];
}

- (void)loadRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mutableRequest = [request isKindOfClass:[NSMutableURLRequest class]] ? (NSMutableURLRequest *)request : [request mutableCopy];
    if (self.addsWPComReferrer) {
        [mutableRequest setValue:WPComReferrerURL forHTTPHeaderField:@"Referer"];
    }
    
    if (self.addsHideMasterbarParameters &&
        ([mutableRequest.URL.host containsString:WPComDomain] || [mutableRequest.URL.host containsString:AutomatticDomain])) {
        mutableRequest.URL = [mutableRequest.URL appendingHideMasterbarParameters];
    }

    [mutableRequest setValue:[WPUserAgent wordPressUserAgent] forHTTPHeaderField:@"User-Agent"];
    [self.webView loadRequest:mutableRequest];
}

- (void)refreshInterface
{
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    self.titleView.titleLabel.text = self.loading ? nil : [self documentTitle];
    self.titleView.subtitleLabel.text = self.webView.request.URL.host;
    
    if ([self.webView.request.URL.absoluteString isEqualToString:@""]) {
        self.optionsButton.enabled = FALSE;
    } else {
        self.optionsButton.enabled = !self.loading;
    }
}

- (void)showBottomToolbarIfNeeded
{
    if (self.secureInteraction) {
        return;
    }

    if (!self.webView.canGoBack && !self.webView.canGoForward) {
        return;
    }
    
    if (self.toolbarBottomConstraint.constant == WPWebViewToolbarShownConstant) {
        return;
    }

    [UIView animateWithDuration:WPWebViewAnimationShortDuration animations:^{
        self.toolbarBottomConstraint.constant = WPWebViewToolbarShownConstant;
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Reachability Helpers

- (void)reloadWhenConnectionRestored
{
    __weak __typeof(self) weakSelf = self;
    self.reachabilityObserver = [ReachabilityUtils observeOnceInternetAvailableWithAction:^{
        [weakSelf loadWebViewRequest];
    }];
}

- (void)stopWaitingForConnectionRestored
{
    if (self.reachabilityObserver != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.reachabilityObserver];
        self.reachabilityObserver = nil;
    }
}

#pragma mark - Properties

- (void)setUrl:(NSURL *)theURL
{
    if (_url == theURL) {
        return;
    }

    // If the URL has no scheme defined, default to http.
    if (![theURL.scheme hasPrefix:@"http"]) {
        NSURLComponents *components = [NSURLComponents componentsWithURL:theURL resolvingAgainstBaseURL:NO];
        components.scheme = @"http";
        theURL = [components URL];
    }

    _url = theURL;
    
    // Prevent double load in viewDidLoad Method
    if (self.isViewLoaded) {
        [self loadWebViewRequest];
    }
}

#pragma mark - IBAction Methods

- (IBAction)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)goBack
{
    [self.webView goBack];
}

- (IBAction)goForward
{
    [self.webView goForward];
}

- (IBAction)showLinkOptions
{
    NSString *permaLink             = [self documentPermalink];
    NSMutableArray *activityItems   = [NSMutableArray array];
    
    [activityItems addObject:[NSURL URLWithString:permaLink]];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:[WPActivityDefaults defaultActivities]];
    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        if (!completed) {
            return;
        }
        [WPActivityDefaults trackActivityType:activityType];
    };

    if ([UIDevice isPad]) {        
        activityViewController.modalPresentationStyle = UIModalPresentationPopover;
        activityViewController.popoverPresentationController.barButtonItem = self.optionsButton;
    }
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DDLogInfo(@"%@ Should Start Loading [%@]", NSStringFromClass([self class]), request.URL.absoluteString);

    NSURLRequest *redirectRequest = [self.authenticator interceptRedirectWithRequest:request];
    if (redirectRequest != NULL) {
        DDLogInfo(@"Found redirect to %@", redirectRequest);
        [self.webView loadRequest:redirectRequest];
        return NO;
    }

    // To handle WhatsApp and Telegraph shares
    // Even though the documentation says that canOpenURL will only return YES for
    // URLs configured on the plist under LSApplicationQueriesSchemes if we don't filter
    // out http requests it also returns YES for those
    if (![request.URL.scheme hasPrefix:@"http"]
        && [[UIApplication sharedApplication] canOpenURL:request.URL]) {
        [[UIApplication sharedApplication] openURL:request.URL
                                           options:nil
                                 completionHandler:nil];
        return NO;
    }

    if (self.navigationDelegate != nil) {
        WebNavigationPolicy *policy = [self.navigationDelegate shouldNavigateWithRequest:request];
        if (policy.redirectRequest != NULL) {
            [self.webView loadRequest:policy.redirectRequest];
        }
        return policy.action == WKNavigationResponsePolicyAllow;
    }

    //  Note:
    //  UIWebView callbacks will get hit for every frame that gets loaded. As a workaround, we'll consider
    //  we're in a "loading" state just for the Top Level request.
    //
    if ([request.mainDocumentURL isEqual:request.URL]) {
        self.loading = YES;
        [self refreshInterface];
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
    DDLogInfo(@"%@ Started Loading [%@]", NSStringFromClass([self class]), aWebView.request.URL);
    
    // Bypass if we're not loading the "Main Document"
    if (!self.loading) {
        return;
    }
    
    [self.progressView startedLoading];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogInfo(@"%@ Error Loading [%@]", NSStringFromClass([self class]), error);
    
    // Bypass if we're not loading the "Main Document"
    if (!self.loading) {
        return;
    }
    
    // Refresh the Interface
    self.loading = NO;
    
    [self.progressView finishedLoading];
    [self refreshInterface];

    // Don't show Ajax Cancelled or Frame Load Interrupted errors
    if (error.code == WPWebViewErrorAjaxCancelled || error.code == WPWebViewErrorFrameLoadInterrupted) {
        return;
    } else if ([error.domain isEqualToString:WPWebViewWebKitErrorDomain] && error.code == WPWebViewErrorPluginHandledLoad) {
        return;
    }

    [self displayLoadError:error];
}

- (void)displayLoadError:(NSError *)error
{
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        [self reloadWhenConnectionRestored];
    } else {
        [WPError showAlertWithTitle: NSLocalizedString(@"Error", @"Generic error alert title") message: error.localizedDescription];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    DDLogInfo(@"%@ Finished Loading [%@]", NSStringFromClass([self class]), aWebView.request.URL);
    
    // Bypass if we're not loading the "Main Document"
    if (!self.loading) {
        return;
    }
    
    self.loading = NO;
    
    [self.progressView finishedLoading];
    [self refreshInterface];
    [self showBottomToolbarIfNeeded];
}

@end
