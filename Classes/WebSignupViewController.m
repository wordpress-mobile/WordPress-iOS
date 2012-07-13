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
	
	NSURLRequest *request = [NSURLRequest requestWithURL:
								[NSURL URLWithString:NSLocalizedString(@"http://wordpress.com/signup?ref=wp-iphone", @"")]];
    self.webView.scalesPageToFit = YES;
	[self.webView loadRequest:request];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (NSString*) getDocumentTitle {
    //load the title from the document
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"]; 
    if ( title != nil && [[title trim] isEqualToString:@""] == false)
        return title;
    
    return NSLocalizedString(@"Sign Up", @"");
}

- (void)dealloc {
    self.webView.delegate = nil;
	[webView release];
	[spinner release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

@end
