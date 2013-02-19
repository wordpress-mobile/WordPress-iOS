//
//  WPWebViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 6/16/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "WPWebViewController.h"
#import "WordPressAppDelegate.h"
#import "PanelNavigationConstants.h"
#import "ReachabilityUtils.h"
#import "WPActivities.h"

@class WPReaderDetailViewController;

@interface WPWebViewController ()
@property (weak, readonly) UIScrollView *scrollView;
@property (nonatomic, strong) UIActionSheet *linkOptionsActionSheet;
- (NSString*) getDocumentPermalink;
- (NSString*) getDocumentTitle;
- (void)upgradeButtonsAndLabels:(NSTimer*)timer;
- (BOOL)setMFMailFieldAsFirstResponder:(UIView*)view mfMailField:(NSString*)field;
- (void)refreshWebView;
- (void)setLoading:(BOOL)loading;
- (void)retryWithLogin;
@end

@implementation WPWebViewController
@synthesize url, wpLoginURL, username, password, detailContent, detailHTML, readerAllItems;
@synthesize webView, toolbar, statusTimer;
@synthesize loadingView, loadingLabel, activityIndicator;
@synthesize iPadNavBar, backButton, forwardButton, refreshButton, spinnerButton, optionsButton;
@synthesize linkOptionsActionSheet = _linkOptionsActionSheet;
@synthesize hidesLinkOptions;
@synthesize shouldScrollToBottom;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];

    self.webView.delegate = nil;
    if ([webView isLoading]) {
        [webView stopLoading];
    }
    self.statusTimer = nil;
    self.linkOptionsActionSheet.delegate = nil;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    
    if (IS_IPHONE)
        self.navigationItem.title = NSLocalizedString(@"Loading...", @"");

    [self setLoading:NO];
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;

    if( IS_IPHONE ) {
        
        if ([[UIButton class] respondsToSelector:@selector(appearance)]) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            
            [btn setImage:[UIImage imageNamed:@"navbar_actions.png"] forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:@"navbar_actions.png"] forState:UIControlStateHighlighted];
            
            UIImage *backgroundImage = [[UIImage imageNamed:@"navbar_button_bg"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
            [btn setBackgroundImage:backgroundImage forState:UIControlStateNormal];
            
            backgroundImage = [[UIImage imageNamed:@"navbar_button_bg_active"] stretchableImageWithLeftCapWidth:4 topCapHeight:0];
            [btn setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
            
            btn.frame = CGRectMake(0.0f, 0.0f, 44.0f, 30.0f);
            
            [btn addTarget:self action:@selector(showLinkOptions) forControlEvents:UIControlEventTouchUpInside];
            
            self.optionsButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
        } else {
            self.optionsButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(showLinkOptions)];
        }
        
        if (!self.hidesLinkOptions) {
            self.navigationItem.rightBarButtonItem = optionsButton;
        }
        
    } else {
        // We want the refresh button to be borderless, but buttons in navbars want a border.
        // We need to compose the refresh button as a UIButton that is used as the UIBarButtonItem's custom view.
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage imageNamed:@"sync_dark"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"sync_lite"] forState:UIControlStateHighlighted];

        btn.frame = CGRectMake(0.0f, 0.0f, 30.0f, 30.0f);
        btn.autoresizingMask =  UIViewAutoresizingFlexibleHeight;
        [btn addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
        refreshButton.customView = btn;
        
        if(self.navigationController && self.navigationController.navigationBarHidden == NO) {
            CGRect frame = webView.frame;
            frame.origin.y -= iPadNavBar.frame.size.height;
            frame.size.height += iPadNavBar.frame.size.height;
            webView.frame = frame;
            self.navigationItem.rightBarButtonItem = refreshButton;
            self.title = NSLocalizedString(@"Loading...", @"");
            [iPadNavBar removeFromSuperview];
            self.iPadNavBar = self.navigationController.navigationBar;
        } else {
            refreshButton.customView = btn;
            iPadNavBar.topItem.title = NSLocalizedString(@"Loading...", @"");
        }
    }
    
    if ([forwardButton respondsToSelector:@selector(setTintColor:)]) {
        UIColor *color = [UIColor UIColorFromHex:0x464646];
        backButton.tintColor = color;
        forwardButton.tintColor = color;
        refreshButton.tintColor = color;
        if ([[toolbar items] count] >= 4) {
            UIBarButtonItem *actionButton = [[toolbar items] objectAtIndex:3];
            actionButton.tintColor = color;
        }
    }
    
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
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillAppear:animated];
        
    if( self.detailContent == nil ) {
        [self setStatusTimer:[NSTimer timerWithTimeInterval:0.75 target:self selector:@selector(upgradeButtonsAndLabels:) userInfo:nil repeats:YES]];
        [[NSRunLoop currentRunLoop] addTimer:[self statusTimer] forMode:NSDefaultRunLoopMode];
    } else {
        //do not set the timer on the detailsView
        //change the arrows to up/down icons
        [backButton setImage:[UIImage imageNamed:@"previous.png"]];
        [forwardButton setImage:[UIImage imageNamed:@"next.png"]];
        
        // Replace refresh button with options button
        backButton.width = (toolbar.frame.size.width / 2.0f) - 10.0f;
        forwardButton.width = (toolbar.frame.size.width / 2.0f) - 10.0f;
        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *items = [NSArray arrayWithObjects:spacer,
                          backButton, spacer,
                          forwardButton, spacer, nil];
        toolbar.items = items;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[self setStatusTimer:nil];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];  
    self.webView.delegate = nil;
    self.webView = nil;
    self.toolbar = nil;
    self.loadingView = nil;
    self.loadingLabel = nil;
    self.activityIndicator = nil;
    self.iPadNavBar = nil;
    self.statusTimer = nil;
    self.optionsButton = nil;
    self.refreshButton = nil;
    self.backButton = nil;
    self.forwardButton = nil;
    self.spinnerButton = nil;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
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

#pragma mark - webView related methods

- (void)setStatusTimer:(NSTimer *)timer
{
 //   [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	if (statusTimer && timer != statusTimer) {
		[statusTimer invalidate];
	}
	statusTimer = timer;
}


- (void)upgradeButtonsAndLabels:(NSTimer*)timer {
    self.backButton.enabled = webView.canGoBack;
    self.forwardButton.enabled = webView.canGoForward;
    if (!isLoading) {
        if (IS_IPAD) {
            if(self.navigationController.navigationBarHidden == NO) {
                self.title = [self getDocumentTitle];
            } else {
                [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
            }
        }
        else
            self.title = [self getDocumentTitle];
    }
}

- (NSString*) getDocumentPermalink {
    NSString *permaLink = [webView stringByEvaluatingJavaScriptFromString:@"Reader2.get_article_permalink();"];
    if ( permaLink == nil || [[permaLink trim] isEqualToString:@""]) {
        // try to get the loaded URL within the webView
        NSURLRequest *currentRequest = [webView request];
        if ( currentRequest != nil) {
            NSURL *currentURL = [currentRequest URL];
           // NSLog(@"Current URL is %@", currentURL.absoluteString);
            permaLink = currentURL.absoluteString;
        }
        
        //make sure we are not sharing URL like this: http://en.wordpress.com/reader/mobile/?v=post-16841252-1828
        if ([permaLink rangeOfString:@"wordpress.com/reader/mobile/"].location != NSNotFound) { 
            permaLink = kMobileReaderURL;                 
        } 
    }
    
    return permaLink;
}   

- (NSString*) getDocumentTitle {
     
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"Reader2.get_article_title();"];
    
    if( title != nil && [[title trim] isEqualToString:@""] == false ) {
        return [title trim];
    } else {
        //load the title from the document
        title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"]; 
        
        if ( title != nil && [[title trim] isEqualToString:@""] == false)
            return title;
        else {
             NSString* permaLink = [self getDocumentPermalink];
             return ( permaLink != nil) ? permaLink : @"";
        }
    }
    
    return @"";
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
    
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnectionWithDelegate:self];
        self.optionsButton.enabled = NO;
        self.refreshButton.enabled = NO;
        return;
    }
    
    if (!needsLogin && self.username && self.password && ![self canIHazCookie]) {
        WPFLog(@"We have login credentials but no cookie, let's try login first");
        [self retryWithLogin];
        return;
    }
    
    NSURL *webURL;
    if (needsLogin) {
        if ( self.wpLoginURL != nil )
            webURL = self.wpLoginURL;
        else //try to guess the login URL
            webURL = [[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"];
    }
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

- (void)setLoading:(BOOL)loading {
	
    if (isLoading == loading)
        return;
    
    self.optionsButton.enabled = !loading;
    
    if (IS_IPAD) {
        CGRect frame = self.loadingView.frame;
        if (loading) {
            frame.origin.y -= frame.size.height;
            [activityIndicator startAnimating];
        } else {
            frame.origin.y += frame.size.height;
            [activityIndicator stopAnimating];
        }
        
        [UIView animateWithDuration:0.2
                         animations:^{self.loadingView.frame = frame;}];
    }
    
	if( self.refreshButton ) {
        self.refreshButton.enabled = !loading;
        // If on iPhone (or iPod Touch) swap between spinner and refresh button
        if (IS_IPHONE) {
            // Build a spinner button if we don't have one
            if( self.spinnerButton == nil ){
                UIActivityIndicatorView *spinner = nil;
                UIActivityIndicatorViewStyle style;
                if ([[UIToolbar class] respondsToSelector:@selector(appearance)]) {
                    style = UIActivityIndicatorViewStyleGray;
                } else {
                    style = UIActivityIndicatorViewStyleWhite;
                }
                spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
                UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(10.0f, 0.0f, 32.0f, 32.0f)];
                [spinner setCenter:customView.center];
                
                [customView addSubview:spinner];
                [spinner startAnimating];
                
                self.spinnerButton = [[UIBarButtonItem alloc] initWithCustomView:customView];
                
            }
            NSMutableArray *newToolbarItems = [NSMutableArray arrayWithArray:toolbar.items];
            NSUInteger spinnerButtonIndex = [newToolbarItems indexOfObject:self.spinnerButton];
            NSUInteger refreshButtonIndex = [newToolbarItems indexOfObject:self.refreshButton];
            if (loading && refreshButtonIndex != NSNotFound) {
                [newToolbarItems replaceObjectAtIndex:refreshButtonIndex withObject:self.spinnerButton];
            } else if(spinnerButtonIndex != NSNotFound) {
                [newToolbarItems replaceObjectAtIndex:spinnerButtonIndex withObject:self.refreshButton];
            }
            toolbar.items = newToolbarItems;
        }
	}
    isLoading = loading;
}

- (void)dismiss {
    [self.panelNavigationController popViewControllerAnimated:NO];
}

- (void)goBack {
    if( self.detailContent != nil ) {
        NSString *prevItemAvailable = [webView stringByEvaluatingJavaScriptFromString:@"Reader2.show_prev_item();"];
        if ( [prevItemAvailable rangeOfString:@"true"].location == NSNotFound )
            self.backButton.enabled = NO;
        else 
            self.backButton.enabled = YES;
        self.forwardButton.enabled = YES;
        if (IS_IPAD) {
            if(self.navigationController.navigationBarHidden == NO) {
                self.title = [self getDocumentTitle];
            } else {
                [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
            }
        }
        else
            self.title = [self getDocumentTitle];
    } else {
        if ([webView isLoading]) {
            [webView stopLoading];
        }
        [webView goBack];
    }
}

- (void)goForward {
    if( self.detailContent != nil ) {
        NSString *nextItemAvailable = [webView stringByEvaluatingJavaScriptFromString:@"Reader2.show_next_item();"];
        if ( [nextItemAvailable rangeOfString:@"true"].location == NSNotFound )
            self.forwardButton.enabled = NO;
        else 
            self.forwardButton.enabled = YES;
        self.backButton.enabled = YES;
        if (IS_IPAD) {
            if(self.navigationController.navigationBarHidden == NO) {
                self.title = [self getDocumentTitle];
            } else {
                [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
            }
        }
        else
            self.title = [self getDocumentTitle];
    } else {
        if ([webView isLoading]) {
            [webView stopLoading];
        }
        [webView goForward];
    }
}

- (void)showLinkOptions{
    if (self.linkOptionsActionSheet) {
        [self.linkOptionsActionSheet dismissWithClickedButtonIndex:-1 animated:NO];
        self.linkOptionsActionSheet = nil;
    }
    NSString* permaLink = [self getDocumentPermalink];
    
    if( permaLink == nil || [[permaLink trim] isEqualToString:@""] ) return; //this should never happen

    if (NSClassFromString(@"UIActivity") != nil) {
        NSString *title = [self getDocumentTitle];
        SafariActivity *safariActivity = [[SafariActivity alloc] init];
        InstapaperActivity *instapaperActivity = [[InstapaperActivity alloc] init];
        PocketActivity *pocketActivity = [[PocketActivity alloc] init];

        NSMutableArray *activityItems = [NSMutableArray array];
        if (title) {
            [activityItems addObject:title];
        }

        [activityItems addObject:[NSURL URLWithString:permaLink]];
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:@[safariActivity, instapaperActivity, pocketActivity]];
        [self presentViewController:activityViewController animated:YES completion:nil];
        return;
    }

    self.linkOptionsActionSheet = [[UIActionSheet alloc] initWithTitle:permaLink delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open in Safari", @"Open in Safari"), NSLocalizedString(@"Mail Link", @"Mail Link"),  NSLocalizedString(@"Copy Link", @"Copy Link"), nil];
    self.linkOptionsActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    if(IS_IPAD ){
        [self.linkOptionsActionSheet showFromBarButtonItem:self.optionsButton animated:YES];
    } else {
        [self.linkOptionsActionSheet showInView:self.view];
    }
}

- (void)reload {
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnectionWithDelegate:self];
        self.optionsButton.enabled = NO;
        self.refreshButton.enabled = NO;
        return;
    }
    [self setLoading:YES];
    [webView reload];
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
    
    //the user clicked a link available in the detailsView, a new webView will be pushed into the stack
    if (![requestedURL isEqual:self.url] && 
        [requestedURLAbsoluteString rangeOfString:@"file://"].location == NSNotFound && 
        self.detailContent != nil &&
        navigationType == UIWebViewNavigationTypeLinkClicked
        ) { 
        
        WPWebViewController *webViewController;
        if (IS_IPAD) {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
        }
        else {
            webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
        }
        [webViewController setUrl:[request URL]];
        if ( self.panelNavigationController  )
            [self.panelNavigationController pushViewController:webViewController fromViewController:self animated:YES];
        return NO;
    }
    
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
    if ( !hasLoadedContent && ([aWebView.request.URL.absoluteString rangeOfString:kMobileReaderDetailURL].location == NSNotFound || self.detailContent)) {
        [aWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Reader2.set_loaded_items(%@);", self.readerAllItems]];
        [aWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Reader2.show_article_details(%@);", self.detailContent]];
        if (IS_IPAD) {
            if(self.navigationController.navigationBarHidden == NO) {
                self.title = [self getDocumentTitle];
            } else {
                [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
            }
        }
        else
            self.navigationItem.title = [self getDocumentTitle];
        
        
        NSString *prevItemAvailable = [aWebView stringByEvaluatingJavaScriptFromString:@"Reader2.is_prev_item();"];
        if ( [prevItemAvailable rangeOfString:@"true"].location == NSNotFound )
            self.backButton.enabled = NO;
        else 
            self.backButton.enabled = YES;
        
        NSString *nextItemAvailable = [aWebView stringByEvaluatingJavaScriptFromString:@"Reader2.is_next_item();"];
        if ( [nextItemAvailable rangeOfString:@"true"].location == NSNotFound )
            self.forwardButton.enabled = NO;
        else 
            self.forwardButton.enabled = YES;
        
        
        hasLoadedContent = YES;
    }
    if (shouldScrollToBottom == YES) {
        self.shouldScrollToBottom = NO;
        CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
        [self.scrollView setContentOffset:bottomOffset animated:YES];
    }
}


#pragma mark -
#pragma mark AlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex > 0) {
        [self refreshWebView];
    }
}


#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *permaLink = [self getDocumentPermalink];
 
    if( permaLink == nil || [[permaLink trim] isEqualToString:@""] ) return; //this should never happen

	if (buttonIndex == 0) {
		NSURL *permaLinkURL;
		permaLinkURL = [[NSURL alloc] initWithString:(NSString *)permaLink];
        [[UIApplication sharedApplication] openURL:(NSURL *)permaLinkURL];		
    } else if (buttonIndex == 1) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        
        NSString *title = [self getDocumentTitle];
        [controller setSubject: [title trim]];                
        
        NSString *body = [permaLink trim];
        [controller setMessageBody:body isHTML:NO];
        
        if (controller) 
            [self.panelNavigationController presentModalViewController:controller animated:YES];        
        [self setMFMailFieldAsFirstResponder:controller.view mfMailField:@"MFRecipientTextField"];
    } else if ( buttonIndex == 2 ) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = permaLink;
    }
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
{
	[self dismissModalViewControllerAnimated:YES];
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
    if ( IS_IPAD ) {
        if(self.navigationController.navigationBarHidden) {
            UINavigationItem *topItem = self.iPadNavBar.topItem;
            topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
        }
    }
}

@end
