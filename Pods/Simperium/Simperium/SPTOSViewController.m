//
//  SPTOSViewController.m
//  Simperium
//
//  Created by Tom Witkin on 8/27/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

NSString *const TOSUrl = @"http://simperium.com/tos/";

#import "SPTOSViewController.h"

@interface SPTOSViewController ()

@end

@implementation SPTOSViewController

- (void)loadView {
    
    if (!webView) {
        webView = [[UIWebView alloc] init];
        webView.delegate = self;
        self.view = webView;
    }
}

- (void)dismissAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityIndicator hidesWhenStopped];
    UIBarButtonItem *activityContainer = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    self.navigationItem.leftBarButtonItem = activityContainer;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAction:)];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:TOSUrl]];
    [webView loadRequest:request];
}

#pragma mark UIWebViewDelegate Methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    return [[NSString stringWithFormat:@"%@", request.URL] isEqualToString:TOSUrl];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    [activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [activityIndicator stopAnimating];
}


@end
