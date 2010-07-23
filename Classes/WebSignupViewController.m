    //
//  WebSignup.m
//  WordPress
//
//  Created by Dan Roundhill on 5/6/10.
//  
//

#import "WebSignupViewController.h"
#import "QuartzCore/QuartzCore.h"

@implementation WebSignupViewController
@synthesize webView, spinner;

- (void)viewDidLoad {
	self.navigationItem.title = @"Sign Up";
	spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	spinner.hidesWhenStopped = YES;
	UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] init];
	buttonItem.customView = spinner;
	self.navigationItem.rightBarButtonItem = buttonItem;
	
	NSURLRequest *request = [NSURLRequest requestWithURL:
								[NSURL URLWithString:@"http://wordpress.com/signup?ref=wp-iphone"]];
	[self.webView loadRequest:request];
}

- (void)webViewDidStartLoad:(UIWebView *)wv {
    NSLog (@"webViewDidStartLoad");
    [spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv {
    NSLog (@"webViewDidFinishLoad");
    [spinner stopAnimating];
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error {
    NSLog (@"webView:didFailLoadWithError");
    [spinner stopAnimating];
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
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[webView release];
	[spinner release];
    [super dealloc];
}


@end
