//
//  WebSignupViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 5/6/10.
//  
//

#import "WebSignupViewController.h"
#import "ReachabilityUtils.h"
#import "SFHFKeychainUtils.h"
#import "NSString+Helpers.h"

@interface WebSignupViewController ()

- (void)loadRequest;
- (void)checkAuth;

@end

@implementation WebSignupViewController

@synthesize webView, spinner;


#pragma mark -
#pragma mark Lifecycle Methods

- (void)dealloc {
    self.webView.delegate = nil;
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
    [self checkAuth];
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


- (void)checkAuth {
    // See if we need to authenticate a .com account so the user doesn't see a sign up screen by mistake. 
    
    if(![ReachabilityUtils isInternetReachable]){
        [ReachabilityUtils showAlertNoInternetConnectionWithDelegate:self];
        return;
    }

    // If we're already authed no need to re-auth.
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://wordpress.com"]];
    for (NSHTTPCookie *cookie in cookies) {
        if([cookie.name isEqualToString:@"wordpress_logged_in"]){
            [self loadRequest];
            return;
        }
    }
    
    // If we don't have a user name don't try to auth.
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
    if (!username) {
        [self loadRequest];
        return;
    }
    
    // Okay.  Try to auth.
    NSError *error;
    NSString *password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"WordPress.com" error:&error];
    
    NSMutableURLRequest *mRequest = [[NSMutableURLRequest alloc] init];
    NSString *requestBody = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=http://wordpress.com",
                             [username stringByUrlEncoding],
                             [password stringByUrlEncoding]];
    
    [mRequest setURL:[NSURL URLWithString:@"https://wordpress.com/wp-login.php"]];
    [mRequest setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    [mRequest setValue:[NSString stringWithFormat:@"%d", [requestBody length]] forHTTPHeaderField:@"Content-Length"];
    [mRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    NSString *userAgent = [NSString stringWithFormat:@"%@", [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"]];
    [mRequest addValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [mRequest setHTTPMethod:@"POST"];
    
     AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:mRequest];

    __weak WebSignupViewController *controller = self;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [controller loadRequest];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [controller loadRequest];
    }];

    [operation start];
}


- (void)loadRequest {
    if(![ReachabilityUtils isInternetReachable]){
        [ReachabilityUtils showAlertNoInternetConnectionWithDelegate:self];
        return;
    }
    
	NSURLRequest *request = [NSURLRequest requestWithURL:
                             [NSURL URLWithString:NSLocalizedString(@"http://wordpress.com/signup?ref=wp-iphone", @"")]];
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
