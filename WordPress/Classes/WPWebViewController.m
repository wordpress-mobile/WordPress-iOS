/*
 * WPWebViewController.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "WPWebViewController.h"
#import "WordPressAppDelegate.h"
#import "ReachabilityUtils.h"
#import "WPActivityDefaults.h"
#import "NSString+Helpers.h"
#import "WPCookie.h"
#import "Constants.h"

@class WPReaderDetailViewController;

@interface WPWebViewController () <UIWebViewDelegate>

@property (weak, readonly) UIScrollView *scrollView;
@property (nonatomic) BOOL isLoading, needsLogin, hasLoadedContent;

@end

@implementation WPWebViewController

- (void)dealloc {
    _webView.delegate = nil;
    if ([_webView isLoading]) {
        [_webView stopLoading];
    }
    _statusTimer = nil;
}

- (BOOL)hidesBottomBarWhenPushed {
    return YES;
}

- (NSString *)statsPrefixForShareActions {
    if (_statsPrefixForShareActions == nil) {
        return @"Webview";
    } else {
        return _statsPrefixForShareActions;
    }
}

- (void)viewDidLoad {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewDidLoad];
    
    if (IS_IPHONE)
        self.navigationItem.title = NSLocalizedString(@"Loading...", @"");

    [self setLoading:NO];
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;

    if (IS_IPHONE) {
        if (!self.hidesLinkOptions) {
            [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:self.optionsButton forNavigationItem:self.navigationItem];
        }
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
        
        if (self.navigationController && self.navigationController.navigationBarHidden == NO) {
            CGRect frame = self.webView.frame;
            frame.origin.y -= self.iPadNavBar.frame.size.height;
            frame.size.height += self.iPadNavBar.frame.size.height;
            self.webView.frame = frame;
            self.navigationItem.rightBarButtonItem = self.refreshButton;
            self.title = NSLocalizedString(@"Loading...", @"");
            [self.iPadNavBar removeFromSuperview];
            self.iPadNavBar = self.navigationController.navigationBar;
        } else {
            self.refreshButton.customView = btn;
            self.iPadNavBar.topItem.title = NSLocalizedString(@"Loading...", @"");
        }
    }

    self.toolbar.translucent = NO;
    self.toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    self.toolbar.tintColor = [UIColor whiteColor];
    
    self.optionsButton.enabled = NO;
    self.webView.scalesPageToFit = YES;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    
    if (self.url) {
        [self refreshWebView];
    } else {
        self.navigationItem.title = NSLocalizedString(@"Loading...", @"");
        [self.webView loadHTMLString:self.detailHTML baseURL:[NSURL URLWithString:@"https://en.wordpress.com"]];     
    }
}

- (void)viewWillAppear:(BOOL)animated {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super viewWillAppear:animated];
        
    if( self.detailContent == nil ) {
        [self setStatusTimer:[NSTimer timerWithTimeInterval:0.75 target:self selector:@selector(upgradeButtonsAndLabels:) userInfo:nil repeats:YES]];
        [[NSRunLoop currentRunLoop] addTimer:[self statusTimer] forMode:NSDefaultRunLoopMode];
    } else {
        //do not set the timer on the detailsView
        //change the arrows to up/down icons
        [self.backButton setImage:[UIImage imageNamed:@"previous.png"]];
        [self.forwardButton setImage:[UIImage imageNamed:@"next.png"]];
        
        // Replace refresh button with options button
        self.backButton.width = (self.toolbar.frame.size.width / 2.0f) - 10.0f;
        self.forwardButton.width = (self.toolbar.frame.size.width / 2.0f) - 10.0f;
        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *items = [NSArray arrayWithObjects:spacer,
                          self.backButton, spacer,
                          self.forwardButton, spacer, nil];
        self.toolbar.items = items;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
	[self setStatusTimer:nil];
    [super viewWillDisappear:animated];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
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

- (BOOL)expectsWidePanel {
    return YES;
}

- (UIBarButtonItem *)optionsButton {
    if (_optionsButton) {
        return _optionsButton;
    }
    UIImage *image = [UIImage imageNamed:@"icon-posts-share"];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showLinkOptions) forControlEvents:UIControlEventTouchUpInside];
    _optionsButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    return _optionsButton;
}


#pragma mark - webView related methods

- (void)setStatusTimer:(NSTimer *)timer {
	if (_statusTimer && timer != _statusTimer) {
		[_statusTimer invalidate];
	}
	_statusTimer = timer;
}

- (void)upgradeButtonsAndLabels:(NSTimer*)timer {
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    if (!_isLoading) {
        if (IS_IPAD) {
            if(self.navigationController.navigationBarHidden == NO) {
                self.title = [self getDocumentTitle];
            } else {
                [self.iPadNavBar.topItem setTitle:[self getDocumentTitle]];
            }
        }
        else {
            self.title = [self getDocumentTitle];
        }
    }
}

- (NSString *)getDocumentPermalink {
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
            permaLink = kMobileReaderURL;                 
        } 
    }
    
    return permaLink;
}   

- (NSString *)getDocumentTitle {
    NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.get_article_title();"];
    if (title != nil && [[title trim] isEqualToString:@""] == NO) {
        return [title trim];
    } else {
        //load the title from the document
        title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"]; 
        
        if ( title != nil && [[title trim] isEqualToString:@""] == NO) {
            return title;
        } else {
             NSString* permaLink = [self getDocumentPermalink];
             return ( permaLink != nil) ? permaLink : @"";
        }
    }
    
    return @"";
}

- (void)loadURL:(NSURL *)webURL {
    // Subclass
}

- (void)refreshWebView {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    
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
    
    NSURL *webURL;
    if (self.needsLogin) {
        if (self.wpLoginURL != nil) {
            webURL = self.wpLoginURL;
        } else { //try to guess the login URL
            webURL = [[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"];
        }
    } else {
        webURL = self.url;
    }

    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL];
    request.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    if (self.needsLogin) {
        NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=%@",
                                  [self.username stringByUrlEncoding],
                                  [self.password stringByUrlEncoding],
                                  [[self.url absoluteString] stringByUrlEncoding]];
        
        if ( self.wpLoginURL != nil )
            [request setURL: self.wpLoginURL];
        else
             [request setURL:[[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"]];
        
        [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"%d", [request_body length]] forHTTPHeaderField:@"Content-Length"];
        [request addValue:@"*/*" forHTTPHeaderField:@"Accept"];
        [request setHTTPMethod:@"POST"];
    }
    [self.webView loadRequest:request];
}

- (void)retryWithLogin {
    self.needsLogin = YES;
    [self refreshWebView];    
}

- (void)setUrl:(NSURL *)theURL {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    if (_url != theURL) {
        _url = theURL;
        if (_url && self.webView) {
            [self refreshWebView];
        }
    }
}

- (void)setLoading:(BOOL)loading {
    if (_isLoading == loading) {
        return;
    }
    
    self.optionsButton.enabled = !loading;
    
    if (IS_IPAD) {
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
        if (IS_IPHONE) {
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
            } else if(spinnerButtonIndex != NSNotFound) {
                [newToolbarItems replaceObjectAtIndex:spinnerButtonIndex withObject:self.refreshButton];
            }
            self.toolbar.items = newToolbarItems;
        }
	}
    _isLoading = loading;
}

- (void)dismiss {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)goBack {
    if (self.detailContent != nil) {
        NSString *prevItemAvailable = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.show_prev_item();"];
        if ( [prevItemAvailable rangeOfString:@"true"].location == NSNotFound )
            self.backButton.enabled = NO;
        else 
            self.backButton.enabled = YES;
        self.forwardButton.enabled = YES;
        if (IS_IPAD) {
            if(self.navigationController.navigationBarHidden == NO) {
                self.title = [self getDocumentTitle];
            } else {
                [self.iPadNavBar.topItem setTitle:[self getDocumentTitle]];
            }
        } else {
            self.title = [self getDocumentTitle];
        }
    } else {
        if ([self.webView isLoading]) {
            [self.webView stopLoading];
        }
        [self.webView goBack];
    }
}

- (void)goForward {
    if (self.detailContent != nil) {
        NSString *nextItemAvailable = [self.webView stringByEvaluatingJavaScriptFromString:@"Reader2.show_next_item();"];
        if ([nextItemAvailable rangeOfString:@"true"].location == NSNotFound) {
            self.forwardButton.enabled = NO;
        } else {
            self.forwardButton.enabled = YES;
        }
        self.backButton.enabled = YES;
        if (IS_IPAD) {
            if (self.navigationController.navigationBarHidden == NO) {
                self.title = [self getDocumentTitle];
            } else {
                [self.iPadNavBar.topItem setTitle:[self getDocumentTitle]];
            }
        } else {
            self.title = [self getDocumentTitle];
        }
    } else {
        if ([self.webView isLoading]) {
            [self.webView stopLoading];
        }
        [self.webView goForward];
    }
}

- (void)showLinkOptions{
    [WPMobileStats trackEventForWPCom:[NSString stringWithFormat:@"%@ - %@", self.statsPrefixForShareActions, StatsEventWebviewClickedShowLinkOptions]];
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
        if (!completed)
            return;
        [WPActivityDefaults trackActivityType:activityType withPrefix:self.statsPrefixForShareActions];
    };
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)reload {
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

// Find the Webview's UIScrollView backwards compatible
- (UIScrollView *)scrollView {
    UIScrollView *scrollView = nil;
    if ([self.webView respondsToSelector:@selector(scrollView)]) {
        scrollView = self.webView.scrollView;
    } else {
        for (UIView* subView in self.webView.subviews) {
            if ([subView isKindOfClass:[UIScrollView class]]) {
                scrollView = (UIScrollView*)subView;
            }
        }
    }
    return scrollView;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
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
    
    //the user clicked a link available in the detailsView, a new webView will be pushed into the stack
    if (![requestedURL isEqual:self.url] && 
        [requestedURLAbsoluteString rangeOfString:@"file://"].location == NSNotFound && 
        self.detailContent != nil &&
        navigationType == UIWebViewNavigationTypeLinkClicked
        ) { 
        
        WPWebViewController *webViewController = [[WPWebViewController alloc] init];
        [webViewController setUrl:[request URL]];
        [self.navigationController pushViewController:webViewController animated:YES];
        return NO;
    }
    
    [self setLoading:YES];        
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DDLogInfo(@"%@ %@: %@", self, NSStringFromSelector(_cmd), error);
    // -999: Canceled AJAX request
    // 102:  Frame load interrupted: canceled wp-login redirect to make the POST
    if (self.isLoading && ([error code] != -999) && [error code] != 102) {
        [WPError showAlertWithTitle:NSLocalizedString(@"Error", nil) message:error.localizedDescription];
    }
    [self setLoading:NO];
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView {
    DDLogInfo(@"%@ %@%@", self, NSStringFromSelector(_cmd), aWebView.request.URL);
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [self setLoading:NO];
    
    if (!self.hasLoadedContent && ([aWebView.request.URL.absoluteString rangeOfString:kMobileReaderDetailURL].location == NSNotFound || self.detailContent)) {
        [aWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Reader2.set_loaded_items(%@);", self.readerAllItems]];
        [aWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Reader2.show_article_details(%@);", self.detailContent]];
        
        if (IS_IPAD) {
            if(self.navigationController.navigationBarHidden == NO) {
                self.title = [self getDocumentTitle];
            } else {
                [self.iPadNavBar.topItem setTitle:[self getDocumentTitle]];
            }
        } else {
            self.navigationItem.title = [self getDocumentTitle];
        }
        
        NSString *prevItemAvailable = [aWebView stringByEvaluatingJavaScriptFromString:@"Reader2.is_prev_item();"];
        if ([prevItemAvailable rangeOfString:@"true"].location == NSNotFound) {
            self.backButton.enabled = NO;
        } else {
            self.backButton.enabled = YES;
        }
        
        NSString *nextItemAvailable = [aWebView stringByEvaluatingJavaScriptFromString:@"Reader2.is_next_item();"];
        if ([nextItemAvailable rangeOfString:@"true"].location == NSNotFound) {
            self.forwardButton.enabled = NO;
        } else {
            self.forwardButton.enabled = YES;
        }
        
        self.hasLoadedContent = YES;
    }
    if (self.shouldScrollToBottom == YES) {
        self.shouldScrollToBottom = NO;
        CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
        [self.scrollView setContentOffset:bottomOffset animated:YES];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - custom methods
//Returns true if the ToAddress field was found any of the sub views and made first responder
//passing in @"MFComposeSubjectView"     as the value for field makes the subject become first responder 
//passing in @"MFComposeTextContentView" as the value for field makes the body become first responder 
//passing in @"RecipientTextField"       as the value for field makes the to address field become first responder 
- (BOOL) setMFMailFieldAsFirstResponder:(UIView*)view mfMailField:(NSString*)field{
    for (UIView *subview in view.subviews) {
        
        NSString *className = [NSString stringWithFormat:@"%@", [subview class]];
        if ([className isEqualToString:field]) {
            //Found the sub view we need to set as first responder
            [subview becomeFirstResponder];
            return YES;
        }
        
        if ([subview.subviews count] > 0) {
            if ([self setMFMailFieldAsFirstResponder:subview mfMailField:field]){
                //Field was found and made first responder in a subview
                return YES;
            }
        }
    }
    
    //field not found in this view.
    return NO;
}

- (void)showCloseButton {
    if (IS_IPAD) {
        if (self.navigationController.navigationBarHidden) {
            UINavigationItem *topItem = self.iPadNavBar.topItem;
            topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:[WPStyleGuide barButtonStyleForBordered] target:self action:@selector(dismiss)];
        }
    }
}

@end
