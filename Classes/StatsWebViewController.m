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

@interface StatsWebViewController () <WPcomLoginViewControllerDelegate> {
    BOOL loadStatsWhenViewAppears;
    BOOL promptCredentialsWhenViewAppears;
    AFHTTPRequestOperation *authRequest;
}
@property (nonatomic, strong) NSString *wporgBlogJetpackUsernameKey;
@property (nonatomic, strong) AFHTTPRequestOperation *authRequest;

+ (NSString *)lastAuthedName;
+ (void)setLastAuthedName:(NSString *)str;

+ (NSString *)getWporgBlogJetpackUsernameKey:(NSString *)urlPath;
+ (void)blogChangedNotification:(NSNotification *)notification;

@end

@implementation StatsWebViewController

#define kAlertTagAPIKey 1
#define kAlertTagCredentials 2

@synthesize blog;
@synthesize currentNode;
@synthesize parsedBlog;
@synthesize wporgBlogJetpackUsernameKey;
@synthesize authRequest;


+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blogChangedNotification:) name:kSelectedBlogChanged object:nil];
}

static NSString *_lastAuthedName = nil;

+ (NSString *)lastAuthedName {
    return _lastAuthedName;
}

+ (void)setLastAuthedName:(NSString *)str {
    if (_lastAuthedName) {
        [_lastAuthedName release];
    }
    _lastAuthedName = [str copy];
}

+ (NSString *)getWporgBlogJetpackUsernameKey:(NSString *)urlPath {
    return [NSString stringWithFormat:@"jetpackblog-%@", urlPath];
}

+ (void)blogChangedNotification:(NSNotification *)notification {
    Blog *blog = [[notification userInfo] objectForKey:@"blog"];
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
        username = [[NSUserDefaults standardUserDefaults] objectForKey:[self getWporgBlogJetpackUsernameKey:[blog hostURL]]];
        password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"WordPress.com" error:&error];
    }
    
    // Skip the auth call to reduce loadtime if its the same username as before.
    NSString *lastAuthedUsername = [[self class] lastAuthedName];
    if ([username isEqualToString:lastAuthedUsername]) {
        return;
    }

    // A password that contains an ampersand will not validate unless we swap the anpersand for its hex code
    password = [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    password = [password stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    NSMutableURLRequest *mRequest = [[[NSMutableURLRequest alloc] init] autorelease];
    NSString *requestBody = [NSString stringWithFormat:@"rememberme=forever&log=%@&pwd=%@",
                             [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                             password];
    
    [mRequest setURL:[NSURL URLWithString:@"https://wordpress.com/wp-login.php"]];
    [mRequest setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    [mRequest setValue:[NSString stringWithFormat:@"%d", [requestBody length]] forHTTPHeaderField:@"Content-Length"];
    [mRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [mRequest setHTTPMethod:@"POST"];
    
    AFHTTPRequestOperation *authRequest = [[[AFHTTPRequestOperation alloc] initWithRequest:mRequest] autorelease];
    [authRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self setLastAuthedName:username];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

    }];
    [authRequest start];
}


- (void)dealloc {
    [blog release];
    [currentNode release];
    [parsedBlog release];
    [wporgBlogJetpackUsernameKey release];
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
            self.wporgBlogJetpackUsernameKey = [[self class] getWporgBlogJetpackUsernameKey:[blog hostURL]];// [NSString stringWithFormat:@"jetpackblog-%@",[blog hostURL]];
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
	if ([blog apiKey] == nil || [[blog blogID] isEqualToNumber:[NSNumber numberWithInt:1]]) {
		//first run or api key was deleted
		[self getUserAPIKey];
	} else if(![blog isWPcom] && [[NSUserDefaults standardUserDefaults] objectForKey:wporgBlogJetpackUsernameKey] == nil) {
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
        //use wpcom preference for self-hosted
        username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:@"WordPress.com" error:&error];
        
        // Safety-net, but probably not needed since we also check in initStats.
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
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Service Unavailable", @"")
                                                            message:NSLocalizedString(@"We were unable to look up information about your blog's stats. The service may be temporarily unavailable.", @"")
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                  otherButtonTitles:NSLocalizedString(@"Retry", @""), nil];
        [alertView setTag:kAlertTagAPIKey];
        [alertView show];
        [alertView release];

    }];
    
    [currentRequest start];
    [httpClient release];
    [webView showRefreshingState];
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
        username = [[NSUserDefaults standardUserDefaults] objectForKey:wporgBlogJetpackUsernameKey];
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
    NSString *requestBody = [NSString stringWithFormat:@"rememberme=forever&log=%@&pwd=%@",
                             [username stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                             password];

    [mRequest setURL:[NSURL URLWithString:@"https://wordpress.com/wp-login.php"]];
    [mRequest setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    [mRequest setValue:[NSString stringWithFormat:@"%d", [requestBody length]] forHTTPHeaderField:@"Content-Length"];
    [mRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    NSString *userAgent = [NSString stringWithFormat:@"%@",[webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"]];
    [mRequest addValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [mRequest setHTTPMethod:@"POST"];

    self.authRequest = [[[AFHTTPRequestOperation alloc] initWithRequest:mRequest] autorelease];
    
    [authRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        authed = YES;
        [[self class] setLastAuthedName:username];
        [self loadStats];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"There was a problem connecting to your stats. Would you like to retry?"
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"Retry?", nil), nil];
        [alertView show];
        [alertView release];
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


- (void)promptForCredentials {
    if (!self.view.window) {
        promptCredentialsWhenViewAppears = YES;
        return;
    }
    
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

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WordPress.com Stats", @"")
                                                        message:NSLocalizedString(@"To load stats for your blog you will need to have the Jetpack plugin installed and correctly configured as well as your WordPress.com login.", @"") 
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Learn More", @"")
                                              otherButtonTitles:NSLocalizedString(@"I'm Ready!", @""), nil];
    alertView.tag = kAlertTagCredentials;
    [alertView show];
    [alertView release];
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
    static BOOL match = NO;
    
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
        NSString *parsedHost = [parsedURL host];
        NSString *blogHost = [blogURL host];
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
            match = YES;
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
        
        if (match) {
            /*
             We've successfully found the wpcom account used for the wporg account's jetpack plugin.
             To avoid a mismatched credentials case, associate the current defaults value for wpcom_username_preference
             with a new key for this jetpack account.
             */
            NSString *jetpackUsernameKey = [NSString stringWithFormat:@"jetpackblog-%@", [blog hostURL]];
            NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
            [[NSUserDefaults standardUserDefaults] setValue:username forKey:jetpackUsernameKey];
            [NSUserDefaults resetStandardUserDefaults];
            
            self.currentNode = nil;
            self.parsedBlog = nil;
            
            // Proceed with the credentials we have.
            [self loadStats];
            
            return;
        } 
        
        // We parsed the whole list but did not find a matching blog.
        // This should mean that the user has a self-hosted blog and we searched the api without
        // the correct credentials, or they have not set up Jetpack.
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