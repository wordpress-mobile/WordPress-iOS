#import "StatsWebViewController.h"
#import "Blog+Jetpack.h"
#import "WordPressAppDelegate.h"
#import "WPAccount.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "WPWebViewController.h"
#import "JetpackSettingsViewController.h"
#import "EditSiteViewController.h"
#import "ReachabilityUtils.h"
#import "NSString+Helpers.h"
#import "ContextManager.h"

NSString * const WPStatsWebBlogKey = @"WPStatsWebBlogKey";

@interface StatsWebViewController () <SettingsViewControllerDelegate> {
    BOOL loadStatsWhenViewAppears;
    BOOL promptCredentialsWhenViewAppears;
    AFHTTPRequestOperation *authRequest;
    UIAlertView *retryAlertView;
}

@property (nonatomic, strong) AFHTTPRequestOperation *authRequest;
@property (assign) BOOL authed;

@end

@implementation StatsWebViewController

@synthesize blog;
@synthesize authRequest;
@synthesize authed = authed;

static NSString *_lastAuthedName = nil;

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    NSString *blogID = [coder decodeObjectForKey:WPStatsWebBlogKey];
    if (!blogID)
        return nil;
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:blogID]];
    if (!objectID)
        return nil;
    
    NSError *error = nil;
    Blog *restoredBlog = (Blog *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredBlog) {
        return nil;
    }
    
    StatsWebViewController *viewController = [[self alloc] init];
    viewController.blog = restoredBlog;
    
    return viewController;
}

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountChangeNotification:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
}

+ (void)handleAccountChangeNotification:(NSNotification *)notification {
    [self setLastAuthedName:[WPAccount defaultWordPressComAccount].username];
}

+ (NSString *)lastAuthedName {
    return _lastAuthedName;
}

+ (void)setLastAuthedName:(NSString *)str {
    _lastAuthedName = [str copy];
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    
    return self;
}

- (void)dealloc {
    DDLogMethod();
    if (authRequest && [authRequest isExecuting]) {
        [authRequest cancel];
    }
    retryAlertView.delegate = nil;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [coder encodeObject:[[self.blog.objectID URIRepresentation] absoluteString] forKey:WPStatsWebBlogKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Stats", nil);
    
    // Bypass AFNetworking for ajax stats.
    webView.useWebViewLoading = YES;

    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if( appDelegate.connectionAvailable == YES ) {
        [self.webView showRefreshingState];
    }
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRefreshedWithOutValidRequest:) name:refreshedWithOutValidRequestNotification object:nil];
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
    DDLogError(@"Auth Failed, showing login screen");
    [self showBlogSettings];
    NSString *title;
    NSString *message;
    if ([blog isWPcom]) {
        title = NSLocalizedString(@"Authentication Error", @"");
        message = NSLocalizedString(@"Invalid username/password. Please update your credentials try again.", @"");
    } else {
        title = NSLocalizedString(@"Jetpack Sign In", @"");
        message = NSLocalizedString(@"Unable to sign in to Jetpack. Please update your credentials try again.", @"");
    }
    [WPError showAlertWithTitle:title message:message];
}


- (void)showBlogSettings {
    [self.webView hideRefreshingState];

    UINavigationController *navController = nil;
    
    if ([blog isWPcom]) {
        EditSiteViewController *controller = [[EditSiteViewController alloc] initWithBlog:self.blog];
        controller.delegate = self;
        controller.isCancellable = YES;
        navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navController.navigationBar.translucent = NO;
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    } else {
        JetpackSettingsViewController *controller = [[JetpackSettingsViewController alloc] initWithBlog:blog];
        controller.showFullScreen = NO;
        __weak JetpackSettingsViewController *safeController = controller;
        [controller setCompletionBlock:^(BOOL didAuthenticate) {
            if (didAuthenticate) {
                [safeController.view removeFromSuperview];
                [safeController removeFromParentViewController];
                self.webView.hidden = NO;
                [self loadStats];
            }
        }];
        [self addChildViewController:controller];
        self.webView.hidden = YES;
        [self.view addSubview:controller.view];
        controller.view.frame = self.view.bounds;
    }
}


- (void)setBlog:(Blog *)aBlog {
    if ([blog isEqual:aBlog]) {
        return;
    }
    
    blog = aBlog;
    if (blog) {
        DDLogInfo(@"Loading Stats for the following blog: %@", [blog url]);

        WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
        if( !appDelegate.connectionAvailable ) {
            [webView hideRefreshingState];
            __weak StatsWebViewController *weakSelf = self;
            [ReachabilityUtils showAlertNoInternetConnectionWithRetryBlock:^{
                [weakSelf loadStats];
            }];
            [webView loadHTMLString:@"<html><head></head><body></body></html>" baseURL:nil];
            
        } else {
            [self initStats];
        }
    } else {
        [webView loadHTMLString:@"<html><head></head><body></body></html>" baseURL:nil];
    }
}


- (void)initStats {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    
	if ([blog isWPcom]) {
		[self loadStats];
		return;
	}

	// Looking for a self-hosted blog with a jetpackClientId and good crednetials.
	BOOL prompt = NO;
	
	if (![blog jetpackBlogID]) {
		// needs latest jetpack
		prompt = YES;
		
	} else {
		// Check for credentials.
		if (![blog.jetpackUsername length] || ![blog.jetpackPassword length]) {
			prompt = YES;
		}
	}
		
    if (prompt) {
        [self promptForCredentials];
    } else {
        [self loadStats];
    }
}


- (void)promptForCredentials {
    if (!self.view.window) {
        promptCredentialsWhenViewAppears = YES;
        return;
    }
    
    [self showBlogSettings];
}



- (void)showRetryAlertView:(StatsWebViewController *)statsWebViewController {
    if (retryAlertView)
        return;


    retryAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
                                                        message:NSLocalizedString(@"There was a problem connecting to your stats. Would you like to retry?", @"")
                                                       delegate:statsWebViewController
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"Retry?", nil), nil];
    [retryAlertView show];
}

- (void)authStats {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    if (authed) {
        [self loadStats];
        return;
    }
    
    NSString *username = @"";
    NSString *password = @"";
    if ([blog isWPcom]) {
        //use set username/pw for wpcom blogs
        username = blog.username;
        password = blog.password;
        
    } else {
        username = blog.jetpackUsername;
        password = blog.jetpackPassword;
    }
    
    // Skip the auth call to reduce loadtime if its the same username as before.
    NSString *lastAuthedUsername = [[self class] lastAuthedName];
    if ([username isEqualToString:lastAuthedUsername]) {
        authed = YES;
        [self loadStats];
        return;
    }

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

    // Clear cookies prior to auth so we don't get a false positive on the login cookie being correctly set in some cases.
    [self clearCookies]; 
    [[self class] setLastAuthedName:nil];
    
    self.authRequest = [[AFHTTPRequestOperation alloc] initWithRequest:mRequest];
    
    __weak StatsWebViewController *statsWebViewController = self;
    [authRequest setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        // wordpress.com/wp-login.php currently returns http200 even when auth fails.
        // Sanity check the cookies to make sure we're actually logged in.
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://wordpress.com"]];
        
        for (NSHTTPCookie *cookie in cookies) {
            if([cookie.name isEqualToString:@"wordpress_logged_in"]){
                // We should be authed.
                DDLogInfo(@"Authed. Loading stats.");
                statsWebViewController.authed = YES;
                [[statsWebViewController class] setLastAuthedName:username];
                [statsWebViewController loadStats];
                return;
            }
        }

        [statsWebViewController showAuthFailed];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Just in case .com is ever edited to return a 401 on auth fail...
        if(operation.response.statusCode == 401){
            // If we failed due to bad credentials...
            [statsWebViewController showAuthFailed];
            
        } else {
            [statsWebViewController showRetryAlertView:statsWebViewController];
        }
    }];
    
    [authRequest start];
    [webView showRefreshingState];
}


- (void)loadStats {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    if (!self.isViewLoaded || !self.view.window) {
        loadStatsWhenViewAppears = YES;
        return;
    }
    
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    if( !appDelegate.connectionAvailable ) {
        __weak StatsWebViewController *weakSelf = self;
        [ReachabilityUtils showAlertNoInternetConnectionWithRetryBlock:^{
            [weakSelf loadStats];
        }];
        return;
    }

    if (!authed) {
        [self authStats];
        return;
    }
    
	NSNumber *blogID = [blog blogID];
	if(![blog isWPcom]) {
		blogID = [blog jetpackBlogID];
	}
	
    NSString *pathStr = [NSString stringWithFormat:@"http://wordpress.com/?no-chrome#!/my-stats/?blog=%@&unit=1", blogID];
    NSMutableURLRequest *mRequest = [[NSMutableURLRequest alloc] init];
    [mRequest setURL:[NSURL URLWithString:pathStr]];
    [mRequest addValue:@"*/*" forHTTPHeaderField:@"Accept"];
    NSString *userAgent = [NSString stringWithFormat:@"%@",[webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"]];
    [mRequest addValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    [webView loadRequest:mRequest];
}


- (void)handleRefreshedWithOutValidRequest:(NSNotification *)notification {
    [self initStats];
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
    
    DDLogInfo(@"The following URL was requested: %@", [request.URL absoluteString]);
    
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
            WPWebViewController *webViewController = [[WPWebViewController alloc] init];
            [webViewController setUrl:request.URL];
            [self.navigationController pushViewController:webViewController animated:YES];
            return NO;
        }
        
    }

    DDLogInfo(@"Stats webView is going to load the following URL: %@", [request.URL absoluteString]);
    return YES;
}


- (void)webViewDidFinishLoad:(WPWebView *)wpWebView {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
   
    // Override super so we do not change our title.
    self.title = @"Stats";
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DDLogInfo(@"%@ %@: %@", self, NSStringFromSelector(_cmd), error);
    if (([error code] != -999) && [error code] != 102) {
        [WPError showAlertWithTitle:NSLocalizedString(@"Error", nil) message:error.localizedDescription];
    }
    // -999: Canceled AJAX request
    // 102:  Frame load interrupted: canceled wp-login redirect to make the POST
}

@end