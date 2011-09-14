//
//  WPWebViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 6/16/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "WPWebViewController.h"


@implementation WPWebViewController
@synthesize url,username,password;
@synthesize webView, toolbar;
@synthesize loadingView, loadingLabel, activityIndicator;
@synthesize needsLogin, isReader;
@synthesize iPadNavBar, backButton, forwardButton;

- (void)dealloc
{
    self.url = nil;
    self.username = nil;
    self.password = nil;
    self.webView = nil;
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
    }
    return self;
}   

#pragma mark - View lifecycle

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
    
    if (self.isReader) {
        // ping stats on refresh of reader
        NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://wordpress.com/reader/mobile/?template=stats&stats_name=home_page_refresh"]] autorelease];
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate]; 
        [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
        [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
    }
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

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)goBack {
    [webView goBack];
    [self performSelector:@selector(userDidTapWebView:) withObject:nil afterDelay:0.5];    
}

- (void)goForward {
    [webView goForward];
    [self performSelector:@selector(userDidTapWebView:) withObject:nil afterDelay:0.5];    
}


- (void)showLinkOptions{
    
    NSString* permaLink = nil;
    NSString* isPermaLinkVisible = [webView stringByEvaluatingJavaScriptFromString:@"jq('#article-main').is(':visible');"];
     
    if ( isPermaLinkVisible != nil && [[isPermaLinkVisible trim] isEqualToString:@"true"]) {
        //the details view is on the screen
        NSLog(@"is Permalink visible? %@", isPermaLinkVisible);
        permaLink = [webView stringByEvaluatingJavaScriptFromString:@"jq( '#article-main' ).find('a.comments_link' ).attr( 'href' );"];
        if ( permaLink == nil || [[permaLink trim] isEqualToString:@""]) {
            permaLink = nil;
        }
    }

    
    UIActionSheet *linkOptionsActionSheet;
    if ( permaLink != nil )
     linkOptionsActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"", @"Link Options") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"View in Safari", @"View in Safari"), NSLocalizedString(@"Copy URL", @"Copy URL"), NSLocalizedString(@"Mail URL", @"Mail URL"), nil];
    
    else
        linkOptionsActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"", @"Link Options") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"View in Safari", @"View in Safari"), NSLocalizedString(@"Copy URL", @"Copy URL"), nil];
    
    linkOptionsActionSheet .actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [linkOptionsActionSheet showInView:self.view];
    [linkOptionsActionSheet  release];
}

- (void)reload {
    [webView reload];
}

- (void)viewDidLoad
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
    isLoading = YES;
    [self setLoading:NO];
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;
    self.webView.scalesPageToFit = YES;
    self.webView.controllerThatObserves = self;
    if (self.url) {
        [self refreshWebView];
    }
    if (self.isReader) {
        // ping stats on load of reader
        NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://wordpress.com/reader/mobile/?template=stats&stats_name=home_page"]] autorelease];
        WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate]; 
        [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
        [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
    }
}

- (void)viewDidUnload
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidUnload];
    self.webView = nil;
    self.toolbar = nil;
    self.loadingView = nil;
    self.loadingLabel = nil;
    self.activityIndicator = nil;
    self.iPadNavBar = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
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
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self setLoading:NO];
    self.backButton.enabled = webView.canGoBack;
    self.forwardButton.enabled = webView.canGoForward;
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:self.url];
        [self dismiss];
		
    } else if (buttonIndex == 1) {
		
        if (webView.request.URL.absoluteString != nil) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = webView.request.URL.absoluteString; 
        }
    } else if ( buttonIndex == 2 && actionSheet.cancelButtonIndex != 2 ) {
        NSString *permaLink = [webView stringByEvaluatingJavaScriptFromString:@"jq( '#article-main' ).find('a.comments_link' ).attr( 'href' );"];
        [self dismiss];

        if( permaLink == nil ) return; //this should never happen
        
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;

        NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"jq( '#article-main' ).find('h1.title' ).text();"];
        if( title != nil ) 
            title = [title trim];
        else
            title = permaLink;
                        
        [controller setSubject:[NSString stringWithFormat:@"Check out this article: %@", title ]];                
        NSString *body = [NSString stringWithFormat:@"Hello,<br /> Check out this article: <a href=\"%@\">%@</a>" , [permaLink trim], title];
        [controller setMessageBody:body isHTML:YES];
        
        if (controller) [self presentModalViewController:controller animated:YES];
        [controller release];
    }
}

#pragma mark - TapDetectingWebViewDelegate
- (void)userDidTapWebView:(id)tapPoint {
     NSLog(@"userDidTapWebView");
    self.backButton.enabled = webView.canGoBack;
    self.forwardButton.enabled = webView.canGoForward;
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
{
	[self dismissModalViewControllerAnimated:YES];
}
@end