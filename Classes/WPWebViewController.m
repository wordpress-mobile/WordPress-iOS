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
@synthesize needsLogin;

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
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil ];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.webView action:@selector(reload)] autorelease];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left"] style:UIBarButtonItemStyleBordered target:self action:@selector(goBack)];
        backButton.enabled = NO;
        self.navigationItem.leftBarButtonItem = backButton;
        [backButton release];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)refreshWebView {
    NSURL *loginURL = [[NSURL alloc] initWithScheme:self.url.scheme host:self.url.host path:@"/wp-login.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginURL];
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
    [loginURL release];

    [self.webView loadRequest:request];
}

- (void)setUrl:(NSURL *)theURL {
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
        self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    }
    isLoading = loading;
}

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)loadInSafari {
    [[UIApplication sharedApplication] openURL:self.url];
    [self dismiss];
}

- (void)goBack {
//    if ([webView canGoBack]) {
        if ([webView isLoading]) {
            [webView stopLoading];
        }
        [webView goBack];
//    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    isLoading = YES;
    [self setLoading:NO];
    self.webView.scalesPageToFit = YES;
    if (self.url) {
        [self refreshWebView];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.webView = nil;
    self.toolbar = nil;
    self.loadingView = nil;
    self.loadingLabel = nil;
    self.activityIndicator = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [self setLoading:YES];
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // -999: Canceled AJAX request
    if (isLoading && ([error code] != -999))
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenWebPageFailed" object:error userInfo:nil];
    [self setLoading:NO];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self setLoading:NO];
}

@end
