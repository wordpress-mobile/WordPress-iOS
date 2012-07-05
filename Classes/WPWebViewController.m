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

@interface WPWebViewController (Private)
@property (readonly) UIScrollView *scrollView;
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
@synthesize iPadNavBar, backButton, forwardButton, refreshButton, optionsButton;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.url = nil;
    self.wpLoginURL = nil;
    self.username = nil;
    self.password = nil;
    self.detailContent = nil;
    self.detailHTML = nil;
    self.webView.delegate = nil;
    self.webView = nil;
    self.statusTimer = nil;
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    isLoading = YES;
    [self setLoading:NO];
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;

    if( IS_IPHONE ) {
        //allows the toolbar to become smaller in landscape mode.
        toolbar.autoresizingMask = toolbar.autoresizingMask | UIViewAutoresizingFlexibleHeight;
        
        if ([[UIToolbar class] respondsToSelector:@selector(appearance)]) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//TODO: Replace with new graphics.  The sync graphics are placeholders.
            [btn setImage:[UIImage imageNamed:@"sync_dark"] forState:UIControlStateNormal];
            [btn setImage:[UIImage imageNamed:@"sync_lite"] forState:UIControlStateHighlighted];
            
            btn.frame = CGRectMake(0.0f, 0.0f, 30.0f, 30.0f);
            btn.autoresizingMask =  UIViewAutoresizingFlexibleHeight;
            [btn addTarget:self action:@selector(showLinkOptions) forControlEvents:UIControlEventTouchUpInside];
            
            self.optionsButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
            
        } else {        
            self.optionsButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                                target:self 
                                                                                action:@selector(showLinkOptions)] autorelease];
        }
        self.navigationItem.rightBarButtonItem = optionsButton;
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
    }
    
    if ([forwardButton respondsToSelector:@selector(setTintColor:)]) {
        UIColor *color = [UIColor UIColorFromHex:0x464646];
        backButton.tintColor = color;
        forwardButton.tintColor = color;
        refreshButton.tintColor = color;
        optionsButton.tintColor = color;
    }
    
    self.optionsButton.enabled = NO;
    self.webView.scalesPageToFit = YES;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
        
    if (self.url) {
        [self refreshWebView];
    } else {
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
        backButton.width = (toolbar.frame.size.width / 2) - 10;
        forwardButton.width = (toolbar.frame.size.width / 2) - 10;
        NSArray *items = [NSArray arrayWithObjects:backButton,
                          [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
                          forwardButton, nil];
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
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPAD) {
        return YES;
    }
    
    if ((UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation)) && interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown)
        return YES;
    
    return NO;
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
		[statusTimer release];
	}
	statusTimer = [timer retain];
}


- (void)upgradeButtonsAndLabels:(NSTimer*)timer {
    self.backButton.enabled = webView.canGoBack;
    self.forwardButton.enabled = webView.canGoForward;
    if (!isLoading) {
        if (IS_IPAD) {
            [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
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
            webURL = [[[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"] autorelease];
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
             [request setURL:[[[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"] autorelease]];
        
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

    self.optionsButton.enabled = !loading;
    
    if (IS_IPAD) {
        CGRect frame = self.loadingView.frame;
        if (loading) {
            frame.origin.y -= frame.size.height;
        } else {
            frame.origin.y += frame.size.height;
        }
        [UIView animateWithDuration:0.2
                         animations:^{self.loadingView.frame = frame;}];
        if( self.refreshButton )
            self.refreshButton.enabled = !loading;
    }
    else {
        if( self.refreshButton ) { //the refresh
            if (!loading) {
                NSArray *items = [NSArray arrayWithObjects:backButton,
                                  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
                                  forwardButton,
                                  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
                                  self.refreshButton, nil];
                toolbar.items = items;
            }
        }
    }
	if( self.refreshButton ) { //the refresh
		if (loading) {
			UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
			
            UIActivityIndicatorView *spinner = nil;
            if ([[UIToolbar class] respondsToSelector:@selector(appearance)]) {
                spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            } else if (IS_IPHONE) {
                spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            }
			[spinner setCenter:customView.center];
			[customView addSubview:spinner];
			
			[spinner startAnimating];
			
			self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:customView] autorelease];
			
			[customView release];
		} else {
            if( IS_IPHONE )
                self.navigationItem.rightBarButtonItem = optionsButton;
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
            [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
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
            [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
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
    NSString* permaLink = [self getDocumentPermalink];
    
    if( permaLink == nil || [[permaLink trim] isEqualToString:@""] ) return; //this should never happen
    
    UIActionSheet *linkOptionsActionSheet = [[UIActionSheet alloc] initWithTitle:permaLink delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open in Safari", @"Open in Safari"), NSLocalizedString(@"Mail Link", @"Mail Link"),  NSLocalizedString(@"Copy Link", @"Copy Link"), nil];
    linkOptionsActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    if(IS_IPAD ){
        [linkOptionsActionSheet showFromBarButtonItem:optionsButton animated:YES];
    } else {
        [linkOptionsActionSheet showInView:self.view];
    }
    [linkOptionsActionSheet  release];
}

- (void)reload {
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
            webViewController = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil] autorelease];
        }
        else {
            webViewController = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil] autorelease];
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
    self.optionsButton.enabled = NO;
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView {
    [FileLogger log:@"%@ %@%@", self, NSStringFromSelector(_cmd), aWebView.request.URL];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self setLoading:NO];
    self.optionsButton.enabled = YES;;
    if ( !hasLoadedContent && ([aWebView.request.URL.absoluteString rangeOfString:kMobileReaderDetailURL].location == NSNotFound || self.detailContent)) {
        [aWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Reader2.set_loaded_items(%@);", self.readerAllItems]];
        [aWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Reader2.show_article_details(%@);", self.detailContent]];
        if (IS_IPAD) {
            [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
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
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *permaLink = [self getDocumentPermalink];
 
    if( permaLink == nil || [[permaLink trim] isEqualToString:@""] ) return; //this should never happen

	if (buttonIndex == 0) {
		NSURL *permaLinkURL;
		permaLinkURL = [[[NSURL alloc] initWithString:(NSString *)permaLink] autorelease];
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
        [controller release];
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


- (void) showCloseButton {
    if ( IS_IPAD ) {
        UINavigationItem *topItem = self.iPadNavBar.topItem;        
        topItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)] autorelease];
    }
}

@end
