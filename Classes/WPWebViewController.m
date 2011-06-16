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
@synthesize webView;

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
    NSString *request_body = [NSString stringWithFormat:@"log=%@&pwd=%@",
                              [self.username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                              [self.password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:[request_body dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];

    [self.webView loadRequest:request];
}

- (void)setUrl:(NSURL *)theURL {
    if (url != theURL) {
        [url release];
        url = [theURL retain];
        [self refreshWebView];
    }
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
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self refreshWebView];
    [self.view addSubview:self.webView];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(loadInSafari)] autorelease];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.webView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Anything except upside down for iPhone
    return (DeviceIsPad() || interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
