//
//  WPWebViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 6/16/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "WPWebViewController.h"

@interface WPWebViewController (Private)
- (NSString*) getDocumentPermalink;
- (NSString*) getDocumentTitle;
- (void)upgradeButtonsAndLabels:(NSTimer*)timer;
- (BOOL)setMFMailFieldAsFirstResponder:(UIView*)view mfMailField:(NSString*)field;
- (void)refreshWebView;
- (void)setLoading:(BOOL)loading;
- (void)retryWithLogin;
@end

@implementation WPWebViewController
@synthesize url, username, password, detailContent, detailHTML, readerAllItems;
@synthesize webView, toolbar, statusTimer;
@synthesize loadingView, loadingLabel, activityIndicator;
@synthesize iPadNavBar, backButton, forwardButton, optionsButton, isRefreshButtonEnabled;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.url = nil;
    self.username = nil;
    self.password = nil;
    self.detailContent = nil;
    self.detailHTML = nil;
    self.webView = nil;
    self.statusTimer = nil;
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
        self.isRefreshButtonEnabled = YES;
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
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;
    self.optionsButton.enabled = NO;
    self.webView.scalesPageToFit = YES;
    //allows the toolbar to become smaller in landscape mode.
    if (!DeviceIsPad()) {
        toolbar.autoresizingMask = toolbar.autoresizingMask | UIViewAutoresizingFlexibleHeight;
        //retina displays have a 2px gap at the bottom, this corrects it
        /* ^ I didn't see a gap on a device or in any simulator version, so commenting this out for now
		if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2){
            toolbar.frame = CGRectMake(toolbar.frame.origin.x, toolbar.frame.origin.y + 2, toolbar.frame.size.width, toolbar.frame.size.height);
            webView.frame = CGRectMake(webView.frame.origin.x, webView.frame.origin.y, webView.frame.size.width, webView.frame.size.height + 2);
        }
		*/
    }
    
    if (self.url) {
        [self refreshWebView];
    } else {
        
/*        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSURL *baseURL = [NSURL fileURLWithPath:path];
        baseURL:baseURL 
        //[NSURL URLWithString:@"http://en.wordpress.com"]
*/
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
        
        //you got pink'd!
        //[toolbar setTintColor:[UIColor colorWithRed:254.0f/255 green:14.0f/255 blue:204.0f/255 alpha:1.0f]];
		[toolbar setTintColor:[UIColor colorWithRed:96.0f/255 green:101.0f/255 blue:111.0f/255 alpha:1.0f]];
    }
    if( self.isRefreshButtonEnabled == NO ) self.navigationItem.rightBarButtonItem.enabled = NO;
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
    self.backButton = nil;
    self.forwardButton = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation)) && interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown)
        return YES;
    
    return NO;
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
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.backButton.enabled = webView.canGoBack;
    self.forwardButton.enabled = webView.canGoForward;
    if (!isLoading) {
        if (DeviceIsPad()) {
            [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
        }
        else
            self.navigationItem.title = [self getDocumentTitle];
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
    
    if (DeviceIsPad()) {
        CGRect frame = self.loadingView.frame;
        if (loading) {
            frame.origin.y -= frame.size.height;
        } else {
            frame.origin.y += frame.size.height;
        }
        [UIView animateWithDuration:0.2
                         animations:^{self.loadingView.frame = frame;}];
        if( self.isRefreshButtonEnabled )
            self.navigationItem.rightBarButtonItem.enabled = !loading;
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }
    else {
        if( self.isRefreshButtonEnabled ) { //the refresh
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
        }
    }
    if (!loading) {
        if (DeviceIsPad()) {
            [iPadNavBar.topItem setTitle:[webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
        }
        else
            self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    }
    isLoading = loading;
}

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)goBack {
    if( self.detailContent != nil ) {
        NSString *prevItemAvailable = [webView stringByEvaluatingJavaScriptFromString:@"Reader2.show_prev_item();"];
        if ( [prevItemAvailable rangeOfString:@"true"].location == NSNotFound )
            self.backButton.enabled = NO;
        else 
            self.backButton.enabled = YES;
        self.forwardButton.enabled = YES;
        if (DeviceIsPad()) {
            [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
        }
        else
            self.navigationItem.title = [self getDocumentTitle];
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
        if (DeviceIsPad()) {
            [iPadNavBar.topItem setTitle:[self getDocumentTitle]];
        }
        else
            self.navigationItem.title = [self getDocumentTitle];
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
    
    linkOptionsActionSheet .actionSheetStyle = UIActionSheetStyleDefault;
    [linkOptionsActionSheet showInView:self.view];
    [linkOptionsActionSheet  release];
}

- (void)reload {
    [webView reload];
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
            WPWebViewController *detailViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil]; 
            detailViewController.url = [request URL]; 
            [self.navigationController pushViewController:detailViewController animated:YES];
            [detailViewController release];
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
    self.optionsButton.enabled = YES;
    
    if ( !hasLoadedContent && ([aWebView.request.URL.absoluteString rangeOfString:kMobileReaderDetailURL].location == NSNotFound || self.detailContent)) {
        [aWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Reader2.set_loaded_items(%@);", self.readerAllItems]];
        [aWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Reader2.show_article_details(%@);", self.detailContent]];
        if (DeviceIsPad()) {
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
        
        if (controller) [self presentModalViewController:controller animated:YES];
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

@end
