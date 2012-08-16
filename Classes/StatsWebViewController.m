//
//  StatsWebViewController.m
//
//  Created by Eric Johnson on 5/31/12.
//

#import "StatsWebViewController.h"
#import "AFHTTPClient.h"
#import "Blog.h"
#import "WordPressAppDelegate.h"
#import "SFHFKeychainUtils.h"
#import "WPcomLoginViewController.h"
#import "AFHTTPRequestOperation.h"
#import "WPWebViewController.h"
#import "WordPressComApi.h"

@interface StatsWebViewController () <WPcomLoginViewControllerDelegate> {
    BOOL loadStatsWhenViewAppears;
    BOOL promptCredentialsWhenViewAppears;
    BOOL foundMatchingBlogInAPI;
    AFHTTPRequestOperation *authRequest;
}
@property (nonatomic, strong) NSString *wporgBlogJetpackKey;
@property (nonatomic, strong) AFHTTPRequestOperation *authRequest;

+ (NSString *)lastAuthedName;
+ (void)setLastAuthedName:(NSString *)str;
+ (NSString *)getWporgBlogJetpackKey:(NSString *)urlPath;
+ (void)handleLogoutNotification:(NSNotification *)notification;

- (void)clearCookies;
- (void)showAuthFailed;
- (void)showWPcomLogin;

@end

@implementation StatsWebViewController

#define kAlertTagAPIKey 1
#define kAlertTagCredentials 2

@synthesize blog;
@synthesize currentNode;
@synthesize parsedBlog;
@synthesize wporgBlogJetpackKey;
@synthesize authRequest;


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

+ (NSString *)getWporgBlogJetpackKey:(NSString *)urlPath {
    return [NSString stringWithFormat:@"jetpackblog-%@", urlPath];
}



- (void)dealloc {
    [blog release];
    [currentNode release];
    [parsedBlog release];
    [wporgBlogJetpackKey release];
    if (authRequest && [authRequest isExecuting]) {
        [authRequest cancel];
    }
    [authRequest release];
    
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
    [self showWPcomLogin];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"JetPack Sign In", @"")
                                                        message:NSLocalizedString(@"Unable to sign in to JetPack. Please update your credentials try again.", @"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}


- (void)showWPcomLogin {
    [self.webView hideRefreshingState];
    
    WPcomLoginViewController *controller = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
    controller.delegate = self;
    controller.isCancellable = YES;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    if(IS_IPAD == YES) {
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self.panelNavigationController presentModalViewController:navController animated:YES];
    
    [navController release];
    [controller release];
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
            self.wporgBlogJetpackKey = [[self class] getWporgBlogJetpackKey:[blog hostURL]];// [NSString stringWithFormat:@"jetpackblog-%@",[blog hostURL]];
        }
        
        WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApp];
        if( appDelegate.connectionAvailable == NO ) {
            UIAlertView *connectionFailAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Problem", @"")
                                                                          message:NSLocalizedString(@"The internet connection appears to be offline.", @"")
                                                                         delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
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


- (void)initStats {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
	if ([[blog blogID] isEqualToNumber:[NSNumber numberWithInt:1]]) {
		// This is a .org blog and we need to look up the blog id assigned by jetpack.
		[self getUserAPIKey];
        
	} else if(![blog isWPcom] && [[NSUserDefaults standardUserDefaults] objectForKey:wporgBlogJetpackKey] == nil) {
        // self-hosted blog and no associated .com login.
        [self promptForCredentials];
        
    } else {
        [self loadStats];
	}
}


- (void)getUserAPIKey {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    NSString *username = @"";
    NSString *password = @"";
    NSError *error;
    if ([blog isWPcom]) {
        //use set username/pw for wpcom blogs
        username = [blog username];
        password = [SFHFKeychainUtils getPasswordForUsername:[blog username] andServiceName:[blog hostURL] error:&error];
    } else {

        username = [[NSUserDefaults standardUserDefaults] objectForKey:wporgBlogJetpackKey];
        password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"WordPress.com" error:&error];
        
        if (!username) {
            [self promptForCredentials];
            return;
        }
    }
    
    NSURL *baseURL = [NSURL URLWithString:@"https://public-api.wordpress.com/"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    [httpClient setAuthorizationHeaderWithUsername:username password:password];
    
    NSMutableURLRequest *mRequest = [httpClient requestWithMethod:@"GET" path:@"get-user-blogs/1.0" parameters:nil];
    
    AFXMLRequestOperation *currentRequest = [[[AFXMLRequestOperation alloc] initWithRequest:mRequest] autorelease];
    
    [currentRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSXMLParser *parser = (NSXMLParser *)responseObject;
        parser.delegate = self;
        [parser parse];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPLog(@"Error calling get-user-blogs : %@", [error description]);
        
        if(operation.response.statusCode == 401){
            // If we failed due to bad credentials...
            [self showAuthFailed];
            
        } else {
            // For errors that are not related to auth...
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Service Unavailable", @"")
                                                                message:NSLocalizedString(@"We were unable to look up information about your blog's stats. The service may be temporarily unavailable.", @"")
                                                               delegate:self 
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                      otherButtonTitles:NSLocalizedString(@"Retry", @""), nil];
            [alertView setTag:kAlertTagAPIKey];
            [alertView show];
            [alertView release];
        }

    }];
    
    [currentRequest start];
    [httpClient release];
    [webView showRefreshingState];
}



- (void)promptForCredentials {
    if (!self.view.window) {
        promptCredentialsWhenViewAppears = YES;
        return;
    }
    
    [self showWPcomLogin];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WordPress.com Stats", @"")
                                                        message:NSLocalizedString(@"To load stats for your blog you will need to have the Jetpack plugin installed and correctly configured as well as your WordPress.com login.", @"") 
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Learn More", @"")
                                              otherButtonTitles:NSLocalizedString(@"I'm Ready!", @""), nil];
    alertView.tag = kAlertTagCredentials;
    [alertView show];
    [alertView release];
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
        password = [SFHFKeychainUtils getPasswordForUsername:[blog username] andServiceName:[blog hostURL] error:&error];
        
    } else {
        /*
         The value of wpcom_username_preference can get mismatched if the user gets happy about adding/removing blogs and signing
         out and back in to load blogs from different wpcom accounts so we don't want to rely on it.
         */
        username = [[NSUserDefaults standardUserDefaults] objectForKey:wporgBlogJetpackKey];
        password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"WordPress.com" error:&error];
    }
    
    // Skip the auth call to reduce loadtime if its the same username as before.
    NSString *lastAuthedUsername = [[self class] lastAuthedName];
    if ([username isEqualToString:lastAuthedUsername]) {
        authed = YES;
        [self loadStats];
        return;
    }

    // A password that contains an ampersand will not validate unless we swap the anpersand for its hex code
    password = [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    password = [password stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    NSMutableURLRequest *mRequest = [[[NSMutableURLRequest alloc] init] autorelease];
    NSString *requestBody = [NSString stringWithFormat:@"log=%@&pwd=%@&redirect_to=http://wordpress.com",
                             [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                             password];

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
#pragma mark XMLParser Delegate Methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	self.currentNode = [NSMutableString string];
    if([elementName isEqualToString:@"blog"]) {
        self.parsedBlog = [NSMutableDictionary dictionary];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (self.currentNode) {
        [self.currentNode appendString:string];
    }	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:@"apikey"]) {
        [blog setValue:currentNode forKey:@"apiKey"];
        [blog dataSave];
        
    } else if([elementName isEqualToString:@"blog"]) {
        // We might get a miss-match due to http vs https or a trailing slash
        // so convert the strings to urls and compare their hosts.
        NSURL *parsedURL = [NSURL URLWithString:[parsedBlog objectForKey:@"url"]];
        NSURL *blogURL = [NSURL URLWithString:blog.url];
        if (![blogURL scheme]) {
            blogURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", blog.url]];
        }
        [FileLogger log:@"Blog URL - %@", blogURL];
        NSString *parsedHost = [NSString stringWithFormat:@"%@%@",[parsedURL host],[parsedURL path]] ;
        NSString *blogHost = [NSString stringWithFormat:@"%@%@",[blogURL host], [blogURL path]];
        NSRange range = [parsedHost rangeOfString:blogHost];

        if (range.length > 0) {
            NSNumber *blogID = [[parsedBlog objectForKey:@"id"] numericValue];
            if ([blogID isEqualToNumber:[self.blog blogID]]) {
                // do nothing.
            } else {
                blog.blogID = blogID;
                [blog dataSave];
            }
            
            // Mark that a match was found but continue.
            // http://ios.trac.wordpress.org/ticket/1251
            foundMatchingBlogInAPI = YES;
            NSLog(@"Matched parsedBlogURL: %@ to blogURL: %@ ", parsedURL, blogURL);
        }
        
        self.parsedBlog = nil;

    } else if([elementName isEqualToString:@"id"]) {
        [parsedBlog setValue:currentNode forKey:@"id"];
        [FileLogger log:@"Blog id - %@", currentNode];
    } else if([elementName isEqualToString:@"url"]) {
        [parsedBlog setValue:currentNode forKey:@"url"];
        [FileLogger log:@"Blog original URL - %@", currentNode];
    } else if([elementName isEqualToString:@"userinfo"]) {
        [parser abortParsing];
        
        if (foundMatchingBlogInAPI) {     
            self.currentNode = nil;
            self.parsedBlog = nil;
            
            // Proceed with the credentials we have.
            [self loadStats];
            
            return;
        } 
        
        // We parsed the whole list but did not find a matching blog.
        // This should mean that the user has a self-hosted blog and we searched the api without
        // the correct credentials, or they have not set up Jetpack.
        // Clear the saved username and prompt for new credentials.
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:wporgBlogJetpackKey];
        [self promptForCredentials];
    }
    
	self.currentNode = nil;
}


#pragma mark -
#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSInteger tag = alertView.tag;
    switch (tag) {
        case kAlertTagAPIKey :
            if (buttonIndex == 0) return; // Cancel

            [self getUserAPIKey]; // Retry

            break;

        case kAlertTagCredentials : 
            if (buttonIndex == 0) {
                // Learn More
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", kJetPackURL]]];
            }
            break;

        default:
            if (buttonIndex > 0) {
                [self loadStats];
            }
            break;
    }
}


#pragma mark -
#pragma mark WPcomLoginViewController Delegate Methods

- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithUsername:(NSString *)username {
    [self dismissModalViewControllerAnimated:YES];

    // In theory we should have good wp.com credentials for .org blog's jetpack linkage.
    // Store the username for later use (we'll clear it if we can't find a matching blog)
    // and query for the api key and blog ID.
    if (![self.blog isWPcom]) {
        // Never should see a .com blog here but...
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:wporgBlogJetpackKey];
        [NSUserDefaults resetStandardUserDefaults];        
    }

    [self getUserAPIKey];
}


- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController {
    [self dismissModalViewControllerAnimated:YES];
    [self.panelNavigationController popViewControllerAnimated:YES];
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

@end