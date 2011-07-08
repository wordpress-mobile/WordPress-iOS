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

#pragma mark - View lifecycle

- (void)refreshWebView {
    NSURL *loginURL = [NSURL URLWithString:[[self.url absoluteString] stringByReplacingOccurrencesOfString:@"wp-admin/" withString:@"wp-login.php"]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginURL];
    if (![loginURL isEqual:self.url]) {
        // It's a /wp-admin url, we need to login first
        NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@",
                                  [self.username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  [self.password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPMethod:@"POST"];
    }

    [self.webView loadRequest:request];
}

- (void)setUrl:(NSURL *)theURL {
    if (url != theURL) {
        [url release];
        url = [theURL retain];
        [self refreshWebView];
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
    
    isLoading = loading;
}

- (void)dismiss {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)loadInSafari {
    [[UIApplication sharedApplication] openURL:self.url];
    [self dismiss];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    isLoading = YES;
    [self setLoading:NO];
    [self refreshWebView];
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
    [self setLoading:NO];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self setLoading:NO];
}

@end
