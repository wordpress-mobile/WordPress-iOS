#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"

@interface WordPressAppDelegate (Private)

- (void)setAppBadge;
- (void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)checkPagesAndCommentsSupported;
- (void)storeCurrentBlog;
- (void)restoreCurrentBlog;
- (void)showSplashView;

@end

@implementation WordPressAppDelegate

static WordPressAppDelegate *wordPressApp = NULL;

@synthesize window;
@synthesize navigationController, alertRunning;

- (id)init {
    if (!wordPressApp) {
        wordPressApp = [super init];
        dataManager = [BlogDataManager sharedDataManager];
    }

    return wordPressApp;
}

+ (WordPressAppDelegate *)sharedWordPressApp {
    if (!wordPressApp) {
        wordPressApp = [[WordPressAppDelegate alloc] init];
    }

    return wordPressApp;
}

- (void)dealloc {
    [navigationController release];
    [window release];
    [dataManager release];
    [super dealloc];
}

#pragma mark -
#pragma mark UIApplicationDelegate methods

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [[Reachability sharedReachability] setNetworkStatusNotificationsEnabled:YES];

    BlogsViewController *rootViewController = [[BlogsViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    self.navigationController = aNavigationController;
    [rootViewController release];

    [window addSubview:[navigationController view]];
    [window makeKeyAndVisible];

    [self checkPagesAndCommentsSupported];
    [self restoreCurrentBlog];
    [self showSplashView];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self storeCurrentBlog];
    [dataManager saveBlogData];
    [self setAppBadge];
}

#pragma mark -
#pragma mark Public methods

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                          message:message
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)showErrorAlert:(NSString *)message {
    [self showAlertWithTitle:@"Error" message:message];
}

#pragma mark -
#pragma mark Private methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kUnsupportedWordpressVersionTag || alertView.tag == kRSDErrorTag) {
        if (buttonIndex == 0) { // Visit Site button.
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://iphone.wordpress.org"]];
        }
    }

    self.alertRunning = NO;
}

- (void)setAppBadge {
    [UIApplication sharedApplication].applicationIconBadgeNumber = [dataManager countOfAwaitingComments];
}

// Code for Checking a Blog configured in 1.1 supports Pages & Comments
// When the iphone WP version upgraded from 1.1 to 1.2
- (void)checkPagesAndCommentsSupported {
    int blogsCount = [dataManager countOfBlogs];

    for (int i = 0; i < blogsCount; i++) {
        [dataManager makeBlogAtIndexCurrent:i];
        NSDictionary *blog = [dataManager blogAtIndex:i];
        NSString *url = [blog valueForKey:@"url"];

        if (url != nil &&[url length] >= 7 &&[url hasPrefix:@"http://"]) {
            url = [url substringFromIndex:7];
        }

        if (url != nil &&[url length]) {
            url = @"wordpress.com";
        }

        [Reachability sharedReachability].hostName = url;

        //Check network connectivity
        if ([[Reachability sharedReachability] internetConnectionStatus]) {
            if (![blog valueForKey:kSupportsPagesAndComments]) {
                [dataManager performSelectorInBackground:@selector(wrapperForSyncPagesAndCommentsForBlog:) withObject:blog];
            }
        }
    }
}

- (void)storeCurrentBlog {
    NSDictionary *currentBlog = [dataManager currentBlog];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (currentBlog) {
        NSString *currentBlogId = [currentBlog objectForKey:kBlogId];
        NSString *currentBlogHostName = [currentBlog objectForKey:kBlogHostName];
        int currentBlogIndex = [dataManager indexForBlogid:currentBlogId hostName:currentBlogHostName];
        
        [defaults setInteger:currentBlogIndex forKey:kCurrentBlogIndex];
    }
    else {
        [defaults removeObjectForKey:kCurrentBlogIndex];
    }
}

- (void)restoreCurrentBlog {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:kCurrentBlogIndex]) {
        int currentBlogIndex = [defaults integerForKey:kCurrentBlogIndex];
        // Sanity check.
        if (currentBlogIndex >= 0) {
            [dataManager makeBlogAtIndexCurrent:currentBlogIndex];
        }
    } 
    else {
        [dataManager resetCurrentBlog];
    }
}

- (void)showSplashView {
    splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    splashView.image = [UIImage imageNamed:@"Default.png"];
    [window addSubview:splashView];
    [window bringSubviewToFront:splashView];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:window cache:YES];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(startupAnimationDone:finished:context:)];
    splashView.alpha = 0.0;
    splashView.frame = CGRectMake(-60, -60, 440, 600);
    [UIView commitAnimations];
}

- (void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [splashView removeFromSuperview];
    [splashView release];
}

@end
