//
//  WebSignupViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 5/6/10.
//  
//

#import "WebSignupViewController.h"

@implementation WebSignupViewController
@synthesize webView, spinner;

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [FlurryAPI logEvent:@"WebSignup"];
	if(DeviceIsPad() == YES) {
		self.view.frame = CGRectMake(0, 0, 500, 400);
	}
	
	self.navigationItem.title = NSLocalizedString(@"Sign Up", @"");
	spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	spinner.hidesWhenStopped = YES;
	UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] init];
	buttonItem.customView = spinner;
	self.navigationItem.rightBarButtonItem = buttonItem;
	
	NSURLRequest *request = [NSURLRequest requestWithURL:
								[NSURL URLWithString:NSLocalizedString(@"http://wordpress.com/signup?ref=wp-iphone", @"")]];
    self.webView.scalesPageToFit = YES;
	[self.webView loadRequest:request];
}

- (void)webViewDidStartLoad:(UIWebView *)wv {
    [spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv {
    [spinner stopAnimating];
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error {
    [spinner stopAnimating];
    if (error != NULL) {
        UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle: [error localizedDescription]
								   message: [error localizedFailureReason]
								   delegate:nil
								   cancelButtonTitle:NSLocalizedString(@"OK", @"") 
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
