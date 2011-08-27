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
@synthesize iPadNavBar;

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
        webURL = [[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"];
    else
        webURL = self.url;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:webURL];
    [request setValue:[NSString stringWithFormat:@"wp-iphone/%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] forHTTPHeaderField:@"User-Agent"];
    [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    if (self.needsLogin || ([[self.url absoluteString] rangeOfString:@"wp-admin/"].location != NSNotFound)) {
        // It's a /wp-admin url, we need to login first
        NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=%@",
                                  [self.username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  [self.password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  [[self.url absoluteString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"%d", [request_body length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPMethod:@"POST"];
    }
    [webURL release];

    [self.webView loadRequest:request];
    
    if (self.isReader) {
        // ping stats on refresh of reader
        NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://wordpress.com/reader/mobile/?template=stats&stats_name=home_page_refresh"]] autorelease];
        [request setValue:@"wp-iphone" forHTTPHeaderField:@"User-Agent"];
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
}

- (void)setUrl:(NSURL *)theURL {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    if (url != theURL) {
        [url release];
        url = [theURL retain];
        if (self.webView) {
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

- (void)showLinkOptions{
    
    UIActionSheet *linkOptionsActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Link Options", @"Link Options") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"View in Safari", @"View in Safari"), NSLocalizedString(@"Copy URL", @"Copy URL"), nil];
    
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
    self.webView.scalesPageToFit = YES;
    if (self.url) {
        [self refreshWebView];
    }
    if (self.isReader) {
        // ping stats on load of reader
        NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://wordpress.com/reader/mobile/?template=stats&stats_name=home_page"]] autorelease];
        [request setValue:@"wp-iphone" forHTTPHeaderField:@"User-Agent"];
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
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
		
    }
	
}

@end
