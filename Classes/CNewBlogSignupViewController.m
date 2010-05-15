    //
//  CNewBlogSignupViewController.m
//  WordPress
//
//  Created by Jonathan Wight on 03/09/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "CNewBlogSignupViewController.h"

@implementation CNewBlogSignupViewController

@synthesize webView;

- (void)dealloc
{
[webView release];
webView = NULL;
//
[super dealloc];
}

- (void)viewDidLoad
{
[super viewDidLoad];

self.title = @"Sign up";

NSURL *theURL = [NSURL URLWithString:@"http://wordpress.com/signup/?ref=wp-iphone"];
NSURLRequest *theRequest = [NSURLRequest requestWithURL:theURL];
[self.webView loadRequest:theRequest];
}

- (void)viewDidUnload
{
[super viewDidUnload];
//
[webView release];
webView = NULL;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
return(YES);
}

//- (void)webViewDidFinishLoad:(UIWebView *)webView
//{
//}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:NULL message:@"Could not load web page" delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:NULL] autorelease];
[theAlert show];
}

@end
