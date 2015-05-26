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
#pragma mark Private Properties
#pragma mark ====================================================================================

@interface WPWebViewController () <UIWebViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic,   weak) IBOutlet UIWebView                *webView;
@property (nonatomic, strong) IBOutlet UIToolbar                *toolbar;
@property (nonatomic, strong) IBOutlet UIView                   *loadingView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView  *activityIndicator;
@property (nonatomic, strong) IBOutlet UILabel                  *loadingLabel;
@property (nonatomic, strong) IBOutlet UIBarButtonItem          *backButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem          *forwardButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem          *refreshButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem          *optionsButton;
@property (nonatomic, strong) UIBarButtonItem                   *spinnerButton;
@property (nonatomic, strong) NSTimer                           *statusTimer;
@property (nonatomic, strong) UIPopoverController               *popover;
@property (nonatomic, assign) BOOL                              isLoading;
@property (nonatomic, assign) BOOL                              needsLogin;
@property (nonatomic, assign) BOOL                              hasLoadedContent;

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
    _statusTimer = nil;
}

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

- (void)viewDidLoad
{
    DDLogMethod();
    [super viewDidLoad];

    [self setLoading:NO];
    self.title = NSLocalizedString(@"Loading...", @"");
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;
    self.backButton.accessibilityLabel = NSLocalizedString(@"Back", @"Spoken accessibility label");
    self.forwardButton.accessibilityLabel = NSLocalizedString(@"Forward", @"Spoken accessibility label");
    self.refreshButton.accessibilityLabel = NSLocalizedString(@"Refresh", @"Spoken accessibility label");
    
    if ([UIDevice isPad] == NO) {
        [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:self.optionsButton forNavigationItem:self.navigationItem];
    } else {
        // We want the refresh button to be borderless, but buttons in navbars want a border.
        // We need to compose the refresh button as a UIButton that is used as the UIBarButtonItem's custom view.
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage imageNamed:@"sync_lite"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"sync"] forState:UIControlStateHighlighted];

        btn.frame = CGRectMake(0.0f, 0.0f, 30.0f, 30.0f);
        btn.autoresizingMask =  UIViewAutoresizingFlexibleHeight;
        [btn addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
        self.refreshButton.customView = btn;

        self.navigationItem.rightBarButtonItem = self.refreshButton;
        self.loadingLabel.text = NSLocalizedString(@"Loading...", @"");
    }

    self.toolbar.translucent = NO;
    self.toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    self.toolbar.tintColor = [UIColor whiteColor];

    self.optionsButton.enabled = NO;
    self.webView.scalesPageToFit = YES;

    [self refreshWebView];
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogMethod()
    [super viewWillAppear:animated];

    [self setStatusTimer:[NSTimer timerWithTimeInterval:0.75 target:self selector:@selector(upgradeButtonsAndLabels:) userInfo:nil repeats:YES]];
    [[NSRunLoop currentRunLoop] addTimer:[self statusTimer] forMode:NSDefaultRunLoopMode];
}

- (void)viewWillDisappear:(BOOL)animated
{
    DDLogMethod()
    [self setStatusTimer:nil];
    [super viewWillDisappear:animated];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    CGFloat height = self.navigationController.navigationBar.frame.size.height;
    CGRect customToolbarFrame = self.toolbar.frame;
    customToolbarFrame.size.height = height;
    customToolbarFrame.origin.y = self.toolbar.superview.bounds.size.height - height;

    CGRect webFrame = self.webView.frame;
    webFrame.size.height = customToolbarFrame.origin.y;

    [UIView animateWithDuration:duration animations:^{
        self.toolbar.frame = customToolbarFrame;
        self.webView.frame = webFrame;
    }];
}

- (BOOL)expectsWidePanel
{
    return YES;
}

- (UIBarButtonItem *)optionsButton
{
    if (_optionsButton) {
        return _optionsButton;
    }
    UIImage *image = [UIImage imageNamed:@"icon-posts-share"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showLinkOptions) forControlEvents:UIControlEventTouchUpInside];
    _optionsButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    _optionsButton.accessibilityLabel = NSLocalizedString(@"Share", @"Spoken accessibility label");
    return _optionsButton;
}

#pragma mark - webView related methods

- (void)setStatusTimer:(NSTimer *)timer
{
    if (_statusTimer && timer != _statusTimer) {
        [_statusTimer invalidate];
    }
    _statusTimer = timer;
}

- (void)upgradeButtonsAndLabels:(NSTimer*)timer
{
    self.backButton.enabled     = self.webView.canGoBack;
    self.forwardButton.enabled  = self.webView.canGoForward;
    if (!_isLoading) {
        self.title = [self getDocumentTitle];
    }
}

- (NSString *)getDocumentPermalink
{
    NSString *permaLink = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.get_article_permalink();"];
    if ( permaLink == nil || [[permaLink trim] isEqualToString:@""]) {
        // try to get the loaded URL within the webView
        NSURLRequest *currentRequest = [self.webView request];
        if ( currentRequest != nil) {
            NSURL *currentURL = [currentRequest URL];
            permaLink = currentURL.absoluteString;
        }

        //make sure we are not sharing URL like this: http://en.wordpress.com/reader/mobile/?v=post-16841252-1828
        if ([permaLink rangeOfString:@"wordpress.com/reader/mobile/"].location != NSNotFound) {
            permaLink = WPMobileReaderURL;
        }
    }

    return permaLink;
}

- (NSString *)getDocumentTitle
{
    NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.get_article_title();"];
    if (title != nil && [[title trim] isEqualToString:@""] == NO) {
        return [title trim];
    }

    //load the title from the document
    title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];

    if ( title != nil && [[title trim] isEqualToString:@""] == NO) {
        return title;
    }

    NSString* permaLink = [self getDocumentPermalink];
    return ( permaLink != nil) ? permaLink : @"";
}

- (void)loadURL:(NSURL *)webURL
{
    // Subclass
}

- (void)refreshWebView
{
    DDLogMethod()

    if (![ReachabilityUtils isInternetReachable]) {
        __weak WPWebViewController *weakSelf = self;
        [ReachabilityUtils showAlertNoInternetConnectionWithRetryBlock:^{
            [weakSelf refreshWebView];
        }];

        self.optionsButton.enabled = NO;
        self.refreshButton.enabled = NO;
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
    [self refreshWebView];
}

- (void)setUrl:(NSURL *)theURL
{
    DDLogMethod()
    if (_url == theURL) {
        return;
    }
    
    _url = theURL;
    if (_url && self.webView) {
        [self refreshWebView];
    }
}

- (void)setLoading:(BOOL)loading
{
    if (_isLoading == loading) {
        return;
    }

    self.optionsButton.enabled = !loading;

    if ([UIDevice isPad]) {
        CGRect frame = self.loadingView.frame;
        if (loading) {
            frame.origin.y -= frame.size.height;
            [self.activityIndicator startAnimating];
        } else {
            frame.origin.y += frame.size.height;
            [self.activityIndicator stopAnimating];
        }

        [UIView animateWithDuration:0.2
                         animations:^{self.loadingView.frame = frame;}];
    }

    if (self.refreshButton) {
        self.refreshButton.enabled = !loading;
        // If on iPhone (or iPod Touch) swap between spinner and refresh button
        if ([UIDevice isPad] == NO) {
            // Build a spinner button if we don't have one
            if (self.spinnerButton == nil) {
                UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                                    initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(10.0f, 0.0f, 32.0f, 32.0f)];
                [spinner setCenter:customView.center];

                [customView addSubview:spinner];
                [spinner startAnimating];

                self.spinnerButton = [[UIBarButtonItem alloc] initWithCustomView:customView];

            }
            NSMutableArray *newToolbarItems = [NSMutableArray arrayWithArray:self.toolbar.items];
            NSUInteger spinnerButtonIndex = [newToolbarItems indexOfObject:self.spinnerButton];
            NSUInteger refreshButtonIndex = [newToolbarItems indexOfObject:self.refreshButton];
            if (loading && refreshButtonIndex != NSNotFound) {
                [newToolbarItems replaceObjectAtIndex:refreshButtonIndex withObject:self.spinnerButton];
            } else if (spinnerButtonIndex != NSNotFound) {
                [newToolbarItems replaceObjectAtIndex:spinnerButtonIndex withObject:self.refreshButton];
            }
            self.toolbar.items = newToolbarItems;
        }
    }
    _isLoading = loading;
}

- (IBAction)dismiss
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)goBack
{
    if (self.webView.isLoading) {
        [self.webView stopLoading];
    }
    [self.webView goBack];
}

- (IBAction)goForward
{
    if (self.webView.isLoading) {
        [self.webView stopLoading];
    }
    [self.webView goForward];
}

- (IBAction)showLinkOptions
{
    NSString* permaLink = [self getDocumentPermalink];

    NSString *title = [self getDocumentTitle];
    NSMutableArray *activityItems = [NSMutableArray array];
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

- (IBAction)reload
{
    if (![ReachabilityUtils isInternetReachable]) {
        __weak WPWebViewController *weakSelf = self;
        [ReachabilityUtils showAlertNoInternetConnectionWithRetryBlock:^{
            [weakSelf refreshWebView];
        }];
        self.optionsButton.enabled = NO;
        self.refreshButton.enabled = NO;
        return;
    }
    [self setLoading:YES];
    [self.webView reload];
}

- (void)dismissPopover
{
    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
}


#pragma mark - UIPopover Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DDLogInfo(@"%@ %@: %@", self, NSStringFromSelector(_cmd), [[request URL] absoluteString]);

    NSURL *requestedURL = [request URL];
    NSString *requestedURLAbsoluteString = [requestedURL absoluteString];

    if (!self.needsLogin && [requestedURLAbsoluteString rangeOfString:@"wp-login.php"].location != NSNotFound) {
        if (self.username && self.password) {
            DDLogInfo(@"WP is asking for credentials, let's login first");
            [self retryWithLogin];
            return NO;
        }
    }

    [self setLoading:YES];
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DDLogInfo(@"%@ %@: %@", self, NSStringFromSelector(_cmd), error);
    // -999: Canceled AJAX request
    // 102:  Frame load interrupted: canceled wp-login redirect to make the POST
    if (self.isLoading && ([error code] != -999) && [error code] != 102) {
        [WPError showAlertWithTitle:NSLocalizedString(@"Error", nil) message:error.localizedDescription];
    }
    [self setLoading:NO];
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
    DDLogInfo(@"%@ %@%@", self, NSStringFromSelector(_cmd), aWebView.request.URL);
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    DDLogMethod()
    [self setLoading:NO];

    if (CGRectGetWidth(self.view.frame) < CGRectGetWidth(self.view.window.bounds)) {
        NSString *js = [NSString stringWithFormat:@"var meta = document.createElement('meta');"
                                                    "meta.setAttribute( 'name', 'viewport' );"
                                                    "meta.setAttribute( 'content', 'width = available-width, initial-scale = 1.0, user-scalable = yes' );"
                                                    "document.getElementsByTagName('head')[0].appendChild(meta)"];
        [aWebView stringByEvaluatingJavaScriptFromString:js];
    }

    if (!self.hasLoadedContent && [aWebView.request.URL.absoluteString rangeOfString:WPMobileReaderDetailURL].location == NSNotFound) {
        self.navigationItem.title = [self getDocumentTitle];
        self.hasLoadedContent = YES;
    }
    if (self.shouldScrollToBottom) {
        self.shouldScrollToBottom = NO;
        
        UIScrollView *scrollView = self.webView.scrollView;
        CGPoint bottomOffset = CGPointMake(0, scrollView.contentSize.height - scrollView.bounds.size.height);
        [scrollView setContentOffset:bottomOffset animated:YES];
    }
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
