//
//  WebSignupViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 5/6/10.
//  
//

#import "WebSignupViewController.h"
#import "ReachabilityUtils.h"

@interface WebSignupViewController ()

- (void)loadRequest;

@end

@implementation WebSignupViewController

@synthesize webView, spinner;


#pragma mark -
#pragma mark Lifecycle Methods

- (void)dealloc {
    self.webView.delegate = nil;
	[webView release];
	[spinner release];
    [super dealloc];
}


- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
	if(IS_IPAD == YES) {
		self.view.frame = CGRectMake(0, 0, 500, 400);
	}
	
	self.navigationItem.title = NSLocalizedString(@"Sign Up", @"");
	spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	spinner.hidesWhenStopped = YES;
	UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] init];
	buttonItem.customView = spinner;
	self.navigationItem.rightBarButtonItem = buttonItem;
    [buttonItem release];
    [self loadRequest];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}


#pragma - 
#pragma instance methods

- (NSString *)getDocumentTitle {
    //load the title from the document
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"]; 
    if ( title != nil && [[title trim] isEqualToString:@""] == false)
        return title;
    
    return NSLocalizedString(@"Sign Up", @"");
}


- (void)loadRequest {
    if(![ReachabilityUtils isInternetReachable]){
        [ReachabilityUtils showAlertNoInternetConnectionWithDelegate:self];
        return;
    }
    
	NSURLRequest *request = [NSURLRequest requestWithURL:
                             [NSURL URLWithString:NSLocalizedString(@"http://wordpress.com/signup?ref=wp-iphone", @"")]];
    self.webView.scalesPageToFit = YES;
	[self.webView loadRequest:request];
}


#pragma --
#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [FileLogger log:@"%@ %@: %@://%@%@", self, NSStringFromSelector(_cmd), [[request URL] scheme], [[request URL] host], [[request URL] path]];
    
    NSURL *requestedURL = [request URL];
    NSString *requestedURLAbsoluteString = [requestedURL absoluteString];
    
    if ([requestedURLAbsoluteString rangeOfString:@"wordpress.com"].location != NSNotFound && 
        [requestedURLAbsoluteString rangeOfString:@"signup"].location != NSNotFound ) {
        return YES;
    }
    
    [[UIApplication sharedApplication] openURL:requestedURL];
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)wv {
    [spinner startAnimating];
    self.navigationItem.title = NSLocalizedString(@"Loading...", @"");
}

- (void)webViewDidFinishLoad:(UIWebView *)wv {
    [spinner stopAnimating];
    self.navigationItem.title = NSLocalizedString(@"Sign Up", @"");
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error {
    [spinner stopAnimating];
    self.navigationItem.title = NSLocalizedString(@"Sign Up", @"");
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


#pragma mark -
#pragma mark AlertView delegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex > 0) {
        [self loadRequest]; // Retry
    }
}


@end
