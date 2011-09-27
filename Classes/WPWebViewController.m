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
- (void)goBackToBlogsList;
- (void)removeNotifications;
- (void)addNotifications;
- (void)refreshWebViewNotification:(NSNotification*)notification;
- (void)refreshWebViewTimer:(NSTimer*)timer;
- (void)refreshWebViewIfNeeded;
@end

@implementation WPWebViewController
@synthesize url,username,password;
@synthesize webView, toolbar, statusTimer, refreshTimer, lastWebViewRefreshDate;
@synthesize loadingView, loadingLabel, activityIndicator;
@synthesize needsLogin, isReader;
@synthesize iPadNavBar, backButton, forwardButton, optionsButton;

- (void)dealloc
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    self.url = nil;
    self.username = nil;
    self.password = nil;
    self.webView = nil;
    self.statusTimer = nil;
    self.refreshTimer = nil;
    self.lastWebViewRefreshDate = nil;
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
        
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(goBackToBlogsList)] autorelease];
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
    if (self.url) {
        [self refreshWebView];
    }
    [self addNotifications];
    [self setRefreshTimer:[NSTimer timerWithTimeInterval:(60*30) target:self selector:@selector(refreshWebViewTimer:) userInfo:nil repeats:YES]];
	[[NSRunLoop currentRunLoop] addTimer:[self refreshTimer] forMode:NSDefaultRunLoopMode];
}

- (void)viewWillAppear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewWillAppear:animated];
    
    //set the title of the back button
    NSArray *tt = self.navigationController.viewControllers;
    NSInteger pos =  [tt count] - 2 ;
    if ( pos > -1 ) {
        self.navigationItem.leftBarButtonItem.title = [[tt objectAtIndex:pos] title] ;
    }
    if (self.isReader) {
        // ping stats on load of reader
        NSString *statsURL = [NSString stringWithFormat:@"%@%@" , kMobileReaderURL, @"?template=stats&stats_name=home_page"];
        NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL]] autorelease];
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate]; 
        [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
        [[[NSURLConnection alloc] initWithRequest:request delegate:nil] autorelease];
    }   
    [self setStatusTimer:[NSTimer timerWithTimeInterval:0.75 target:self selector:@selector(upgradeButtonsAndLabels:) userInfo:nil repeats:YES]];
	[[NSRunLoop currentRunLoop] addTimer:[self statusTimer] forMode:NSDefaultRunLoopMode];
}

- (void)viewWillDisappear:(BOOL)animated {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	[self setStatusTimer:nil];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];  
   	[self setRefreshTimer:nil];
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
    [self removeNotifications];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (DeviceIsPad())
        return YES;
    else if ( isTransitioning ) {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
    return YES;
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
    if ( ! webView.loading ) {
        if( fabs( [self.lastWebViewRefreshDate timeIntervalSinceNow] ) > (60*30) ) //30minutes 
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

- (void)upgradeButtonsAndLabels:(NSTimer*)timer {
 //   [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
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
    NSString *permaLink = [webView stringByEvaluatingJavaScriptFromString:@"Reader.get_article_permalink();"];
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
     
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"Reader.get_article_title();"];
    
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

- (void)refreshWebView {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    NSURL *webURL;
    if (needsLogin)
        webURL = [[[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"] autorelease];
    else
        webURL = self.url;
    
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate]; 
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL];
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    if (self.needsLogin || ([[self.url absoluteString] rangeOfString:@"wp-admin/"].location != NSNotFound)) {
        // It's a /wp-admin url, we need to login first
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
    self.lastWebViewRefreshDate = [NSDate date];    
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
    
    self.lastWebViewRefreshDate = [NSDate date];  
    
    CGRect frame = self.loadingView.frame;
    if (loading) {
        frame.origin.y -= frame.size.height;
    } else {
        frame.origin.y += frame.size.height;
    }
    [UIView animateWithDuration:0.2
                     animations:^{self.loadingView.frame = frame;}];
    self.navigationItem.rightBarButtonItem.enabled = !loading;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    if (!loading) {
        if (DeviceIsPad()) {
            [iPadNavBar.topItem setTitle:[webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
        }
        else
            self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    }
    isLoading = loading;
}

- (void) goBackToBlogsList {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
    if (DeviceIsPad() == NO) {
		UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
		if(UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
			isTransitioning = YES;
			UIViewController *garbageController = [[[UIViewController alloc] init] autorelease]; 
			[self.navigationController pushViewController:garbageController animated:NO]; 
			[self.navigationController popViewControllerAnimated:NO];
			isTransitioning = NO;
		}
	}
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)goBack {
    [webView goBack];
}

- (void)goForward {
    [webView goForward];
}

- (void)showLinkOptions{
    NSString* permaLink = [self getDocumentPermalink];
    
    if( permaLink == nil || [[permaLink trim] isEqualToString:@""] ) return; //this should never happen
    
    UIActionSheet *linkOptionsActionSheet = [[UIActionSheet alloc] initWithTitle:permaLink delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open in Safari", @"Open in Safari"), NSLocalizedString(@"Mail Link", @"Mail Link"),  NSLocalizedString(@"Copy Link", @"Copy Link"), nil];
    
    linkOptionsActionSheet .actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [linkOptionsActionSheet showInView:self.view];
    [linkOptionsActionSheet  release];
}

- (void)reload {
    if (self.isReader) {
        // ping stats on refresh of reader
        NSString *statsURL = [NSString stringWithFormat:@"%@%@" , kMobileReaderURL, @"?template=stats&stats_name=home_page_refresh"];
        NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL  ]] autorelease];
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate]; 
        [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
        [[[NSURLConnection alloc] initWithRequest:request delegate:nil] autorelease];
    }
    [webView reload];
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [FileLogger log:@"%@ %@: %@", self, NSStringFromSelector(_cmd), [[request URL] absoluteString]];
    [self setLoading:YES];
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [FileLogger log:@"%@ %@: %@", self, NSStringFromSelector(_cmd), error];
    // -999: Canceled AJAX request
    if (isLoading && ([error code] != -999))
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenWebPageFailed" object:error userInfo:nil];
    [self setLoading:NO];
    self.optionsButton.enabled = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self setLoading:NO];
    self.optionsButton.enabled = YES;
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