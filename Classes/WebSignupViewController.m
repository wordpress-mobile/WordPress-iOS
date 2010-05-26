    //
//  WebSignup.m
//  WordPress
//
//  Created by Dan Roundhill on 5/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WebSignupViewController.h"
#import "QuartzCore/QuartzCore.h"


@implementation WebSignupViewController
@synthesize webView, cancelBtn, activityIndicator;

-(IBAction) cancel:(id) sender{
	
	UIView *currentView = self.view;
	UIView *theWindow = [currentView superview];
	
	// remove the current view and replace with myView1
	[currentView removeFromSuperview];
	
	// set up an animation for the transition between the views
	CATransition *animation = [CATransition animation];
	[animation setDuration:0.5];
	[animation setType:kCATransitionPush];
	[animation setSubtype:kCATransitionFromLeft];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	
	[[theWindow layer] addAnimation:animation forKey:@"CancelWebSignup"];
}

- (void)webViewDidStartLoad:(UIWebView *)wv {
    NSLog (@"webViewDidStartLoad");
    [activityIndicator startAnimating];
	activityIndicator.alpha = 1.0f;
}

- (void)webViewDidFinishLoad:(UIWebView *)wv {
    NSLog (@"webViewDidFinishLoad");
    [activityIndicator stopAnimating];
	activityIndicator.alpha = 0.0f;
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error {
    NSLog (@"webView:didFailLoadWithError");
    [activityIndicator stopAnimating];
	activityIndicator.alpha = 0.0f;
    if (error != NULL) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle: [error localizedDescription]
								   message: [error localizedFailureReason]
								   delegate:nil
								   cancelButtonTitle:@"OK" 
								   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
    }
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad {
	
	NSString *urlAddress = @"http://wordpress.com/signup?ref=wp-iphone";
	
	//Create a URL object.
	NSURL *url = [NSURL URLWithString:urlAddress];
	
	//URL Requst Object
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	
	//Load the request in the UIWebView.
	[webView loadRequest:requestObj];
}


- (void)dealloc {
	[activityIndicator release];
	[webView release];
	[cancelBtn release];
    [super dealloc];
}


@end
