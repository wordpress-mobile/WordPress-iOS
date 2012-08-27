//
//  StatsWebViewController.m
//
//  Created by Eric Johnson on 5/31/12.
//

#import "StatsWebViewController.h"
#import "Blog.h"
#import "WordPressAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "WordPressComApi.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "WPWebViewController.h"
#import "FileLogger.h" 
#import "JetpackAuthUtil.h"
#import "JetpackSettingsViewController.h"
#import "EditSiteViewController.h"

@interface StatsWebViewController () <SettingsViewControllerDelegate, JetpackAuthUtilDelegate> {
    BOOL loadStatsWhenViewAppears;
    BOOL promptCredentialsWhenViewAppears;
    AFHTTPRequestOperation *authRequest;
    JetpackAuthUtil *jetpackAuthUtil;
}

@property (nonatomic, strong) NSString *wporgBlogJetpackKey;
@property (nonatomic, strong) AFHTTPRequestOperation *authRequest;
@property (nonatomic, strong) JetpackAuthUtil *jetpackAuthUtil;

+ (NSString *)lastAuthedName;
+ (void)setLastAuthedName:(NSString *)str;
+ (void)handleLogoutNotification:(NSNotification *)notification;

- (void)clearCookies;
- (void)showAuthFailed;
- (void)showBlogSettings;

@end

@implementation StatsWebViewController

@synthesize blog;
@synthesize wporgBlogJetpackKey;
@synthesize authRequest;
@synthesize jetpackAuthUtil;

static NSString *_lastAuthedName = nil;

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogoutNotification:) name:WordPressComApiDidLogoutNotification object:nil];
}

+ (void)handleLogoutNotification:(NSNotification *)notification {
    [self setLastAuthedName:nil];
}

+ (NSString *)lastAuthedName {
    return _lastAuthedName;
}

+ (void)setLastAuthedName:(NSString *)str {
    if (_lastAuthedName) {
        [_lastAuthedName release];
    }
    _lastAuthedName = [str copy];
}


- (void)dealloc {
    [blog release];
    [wporgBlogJetpackKey release];
    if (authRequest && [authRequest isExecuting]) {
        [authRequest cancel];
    }
    [authRequest release];
    jetpackAuthUtil.delegate = nil;
    [jetpackAuthUtil release];
    
    [super dealloc];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Stats";
    
    // Bypass AFNetworking for ajax stats.
    webView.useWebViewLoading = YES;
    [self.webView showRefreshingState];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    /*
    [self.webView stringByEvaluatingJavaScriptFromString:
     [NSString stringWithFormat:@"%@", 
      @"window.onerror = function(errorMessage,url,lineNumber) { payload = 'url='+url; payload += '&message=' + errorMessage;  payload += '&line=' + lineNumber; var img = new Image();  img.src = 'http://192.168.1.103/errormonitor.php'+'?error=scriptruntime&'+payload; return true;}"]
     ];
     */
    if (promptCredentialsWhenViewAppears) {
        promptCredentialsWhenViewAppears = NO;
        [self promptForCredentials];
    } else if (loadStatsWhenViewAppears) {
        loadStatsWhenViewAppears = NO;
        [self loadStats];
    }
}


#pragma mark -
#pragma mark Instance Methods

- (void)clearCookies {
    NSArray *arr = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://wordpress.com"]];
    for(NSHTTPCookie *cookie in arr){
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}


- (void)showAuthFailed {
    WPLog(@"Auth Failed, showing login screen");
    [self showBlogSettings];
    if ([blog isWPcom]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Auth Error", @"")
                                                            message:NSLocalizedString(@"Invalid username/password. Please update your credentials try again.", @"")
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];   
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Jetpack Sign In", @"")
                                                            message:NSLocalizedString(@"Unable to sign in to Jetpack. Please update your credentials try again.", @"")
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];        
    }
}


- (void)showBlogSettings {
    [self.webView hideRefreshingState];

    UINavigationController *navController = nil;
    
    if ([blog isWPcom]) {
        EditSiteViewController *controller = [[[EditSiteViewController alloc] initWithNibName:nil bundle:nil] autorelease];
        controller.delegate = self;
        controller.isCancellable = YES;
        controller.blog = self.blog;
        navController = [[[UINavigationController alloc] initWithRootViewController:controller] autorelease];
    } else {
        JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithNibName:nil bundle:nil];
        controller.delegate = self;
        controller.isCancellable = YES;
        controller.blog = self.blog;
        navController = [[UINavigationController alloc] initWithRootViewController:controller];
    }
    
    
    if(IS_IPAD == YES) {
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self.panelNavigationController presentModalViewController:navController animated:YES];
    
//    [navController release];

}


- (void)setBlog:(Blog *)aBlog {
    if ([blog isEqual:aBlog]) {
        return;
    }
    
    if (blog) {
        [blog release]; blog = nil;
    }
    blog = [aBlog retain];
    if (blog) {
        [FileLogger log:@"Loading Stats for the following blog: %@", [blog url]];
        if (![blog isWPcom]) {
            self.wporgBlogJetpackKey = [JetpackAuthUtil getWporgBlogJetpackKey:[blog hostURL]];
        }
        
        WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApp];
        if( appDelegate.connectionAvailable == NO ) {
            UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Problem", @"")
                                                                          message:NSLocalizedString(@"The internet connection appears to be offline.", @"")
                                                                         delegate:nil 
                                                                cancelButtonTitle:NSLocalizedString(@"OK", @"") 
                                                                otherButtonTitles:NSLocalizedString(@"Retry", @""), nil];
            [connectionFailAlert show];
            [connectionFailAlert release];
            [webView loadHTMLString:@"<html><head></head><body></body></html>" baseURL:nil];
            
        } else {
            [self initStats];
        }
    } else {
        [webView loadHTMLString:@"<html><head></head><body></body></html>" baseURL:nil];
    }
}


- (NSString *)percentEscapeString: (NSString *)string {
    //only use this for escaping parameters
    NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
    [encodedString autorelease];
    return encodedString; 
}


- (void)initStats {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    BOOL prompt = NO;
	if ([[blog blogID] isEqualToNumber:[NSNumber numberWithInt:1]]) {
		// This is a .org blog and we need to look up the blog id assigned by Jetpack.
        NSString *username = [JetpackAuthUtil getJetpackUsernameForBlog:blog];
        NSString *password = [JetpackAuthUtil getJetpackPasswordForBlog:blog];

        if ([username length] > 0 && [password length] > 0) {
            // try to validate
            if (!jetpackAuthUtil) {
                self.jetpackAuthUtil = [[[JetpackAuthUtil alloc] init] autorelease];
                jetpackAuthUtil.delegate = self;
            }
            [jetpackAuthUtil validateCredentialsForBlog:blog withUsername:username andPassword:password];

        } else {
            prompt = YES;
            
        }
        
	} else if(![blog isWPcom] && [JetpackAuthUtil getJetpackUsernameForBlog:blog] == nil) {
        // self-hosted blog and no associated .com login.
        prompt = YES;
    } else {
        [self loadStats];
	}
    if (prompt) {
        NSString *msg = kNeedJetpackLogIn;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Jetpack Needed" 
                                                            message:msg 
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK") 
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        [alertView release];
        
        [self promptForCredentials];
    }
}


- (void)promptForCredentials {
    if (!self.view.window) {
        promptCredentialsWhenViewAppears = YES;
        return;
    }
    
    [self showBlogSettings];
}



- (void)authStats {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    if (authed) {
        [self loadStats];
        return;
    }
    
    NSString *username = @"";
    NSString *password = @"";
    NSError *error;
    if ([blog isWPcom]) {
        //use set username/pw for wpcom blogs
        username = [blog username];
        password = [SFHFKeychainUtils getPasswordForUsername:[blog username] andServiceName:@"WordPress.com" error:&error];
        
    } else {
        username = [JetpackAuthUtil getJetpackUsernameForBlog:blog];
        password = [JetpackAuthUtil getJetpackPasswordForBlog:blog];
    }
    
    // Skip the auth call to reduce loadtime if its the same username as before.
    NSString *lastAuthedUsername = [[self class] lastAuthedName];
    if ([username isEqualToString:lastAuthedUsername]) {
        authed = YES;
        [self loadStats];
        return;
    }

    NSMutableURLRequest *mRequest = [[[NSMutableURLRequest alloc] init] autorelease];
    NSString *requestBody = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=http://wordpress.com",
                             [self percentEscapeString:username],
                             [self percentEscapeString:password]];

    [mRequest setURL:[NSURL URLWithString:@"https://wordpress.com/wp-login.php"]];
    [mRequest setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    [mRequest setValue:[NSString stringWithFormat:@"%d", [requestBody length]] forHTTPHeaderField:@"Content-Length"];
    [mRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    NSString *userAgent = [NSString stringWithFormat:@"%@", [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"]];
    [mRequest addValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [mRequest setHTTPMethod:@"POST"];

    // Clear cookies prior to auth so we don't get a false positive on the login cookie being correctly set in some cases.
    [self clearCookies]; 
    [[self class] setLastAuthedName:nil];
    
    self.authRequest = [[[AFHTTPRequestOperation alloc] initWithRequest:mRequest] autorelease];
    
    [authRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        // wordpress.com/wp-login.php currently returns http200 even when auth fails.
        // Sanity check the cookies to make sure we're actually logged in.
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://wordpress.com"]];
        
        for (NSHTTPCookie *cookie in cookies) {
            if([cookie.name isEqualToString:@"wordpress_logged_in"]){
                // We should be authed.
                WPLog(@"Authed. Loading stats.");
                authed = YES;
                [[self class] setLastAuthedName:username];
                [self loadStats];
                return;
            }
        }

        [self showAuthFailed];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Just in case .com is ever edited to return a 401 on auth fail...
        if(operation.response.statusCode == 401){
            // If we failed due to bad credentials...
            [self showAuthFailed];
            
        } else {

            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
                                                                message:NSLocalizedString(@"There was a problem connecting to your stats. Would you like to retry?", @"")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                      otherButtonTitles:NSLocalizedString(@"Retry?", nil), nil];
            [alertView show];
            [alertView release];
        }
    }];
    
    [authRequest start];
    [webView showRefreshingState];
}


- (void)loadStats {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    if (!self.isViewLoaded || !self.view.window) {
        loadStatsWhenViewAppears = YES;
        return;
    }
    
    if (!authed) {
        [self authStats];
        return;
    }
    
    NSString *pathStr = [NSString stringWithFormat:@"http://wordpress.com/?no-chrome#!/my-stats/?blog=%@&unit=1", [blog blogID]];
    NSMutableURLRequest *mRequest = [[[NSMutableURLRequest alloc] init] autorelease];
    [mRequest setURL:[NSURL URLWithString:pathStr]];
    [mRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    NSString *userAgent = [NSString stringWithFormat:@"%@",[webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"]];
    [mRequest addValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    [webView loadRequest:mRequest];
}


#pragma mark -
#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex > 0) { // retry
        [self loadStats];
    }
}


#pragma mark -
#pragma mark JetpackSettingsViewController Delegate Methods

- (void)controllerDidDismiss:(JetpackSettingsViewController *)controller cancelled:(BOOL)cancelled {
    if (!cancelled) {
        [self performSelector:@selector(initStats) withObject:nil afterDelay:0.5f];
    }
}


#pragma mark -
#pragma mark WPWebView Delegate Methods

- (BOOL)wpWebView:(WPWebView *)wpWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    [FileLogger log:@"The following URL was requested: %@", [request.URL absoluteString]]; 
    
    // On an ajax powered page like stats that manage state via the url hash, if we spawn a new controller when tapping on a link 
    // (like we do in the WPChromelessWebViewController)
    // and then tap on the same link again, the second tap will not trigger the UIWebView delegate methods, and the new page will load
    // in the webview in which the link was tapped instead of spawning a new controller.
    // To avoid this we'll override the super implementation and just handle all internal links here.
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        
        // If the url is not part of the webstats then handle it differently.
        NSString *host = request.URL.host;
        NSString *query = request.URL.query;
        if (!query) query = @"";
        
        if ([host rangeOfString:@"wordpress.com"].location == NSNotFound ||
            [query rangeOfString:@"no-chrome"].location == NSNotFound) {
            WPWebViewController *controller;
            if (IS_IPAD) {
                controller = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil] autorelease];
            } else {
                controller = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil] autorelease];
            }
            [controller setUrl:request.URL];
            [self.panelNavigationController pushViewController:controller fromViewController:self animated:YES];
            return NO;
        }
        
    }

    [FileLogger log:@"Stats webView is going to load the following URL: %@", [request.URL absoluteString]];
    return YES;
}


- (void)webViewDidFinishLoad:(WPWebView *)wpWebView {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
   
    // Override super so we do not change our title.
    self.title = @"Stats";
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [FileLogger log:@"%@ %@: %@", self, NSStringFromSelector(_cmd), error];
    if ( ([error code] != -999) && [error code] != 102 )
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenWebPageFailed" object:error userInfo:nil];
    // -999: Canceled AJAX request
    // 102:  Frame load interrupted: canceled wp-login redirect to make the POST
}


#pragma mark -
#pragma mark JetpackUtilDelegate

- (void)jetpackAuthUtil:(JetpackAuthUtil *)util didValidateCredentailsForBlog:(Blog *)blog {
    [self initStats];
}


- (void)jetpackAuthUtil:(JetpackAuthUtil *)util noRecordForBlog:(Blog *)blog {
    [self showBlogSettings];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not retrieve stats", @"")
                                                        message:NSLocalizedString(@"Unable to retrieve stats. Either the blog is not connected to Jetpack, or its connected to a different account.", @"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles: nil];
    [alertView show];
    [alertView release];
}


- (void)jetpackAuthUtil:(JetpackAuthUtil *)util errorValidatingCredentials:(Blog *)blog withError:(NSString *)errorMessage {
    [self showBlogSettings];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error validating Jetpack", @"")
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

@end