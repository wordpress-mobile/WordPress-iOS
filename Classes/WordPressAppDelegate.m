#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"

@interface WordPressAppDelegate (Private)

- (void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)checkPagesAndCommentsSupported;
- (void)setCurrentBlog;
- (void)showSplashView;

@end


@implementation WordPressAppDelegate

static WordPressAppDelegate *wordPressApp = NULL;

@synthesize window;
@synthesize navigationController, alertRunning;

- (id)init {
	if (!wordPressApp) {
		wordPressApp = [super init];
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
	[self setCurrentBlog];
	[self showSplashView];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];

    NSString *current_blog_id = [[dataManager currentBlog] objectForKey:@"blogid"];
    NSString *current_blog_hostname = [[dataManager currentBlog] objectForKey:@"blog_host_name"];
    int current_blog_index = [dataManager indexForBlogid:current_blog_id hostName:current_blog_hostname];
        
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:current_blog_index forKey:kCurrentBlogIndex];

	[dataManager saveBlogData];
    
	[UIApplication sharedApplication].applicationIconBadgeNumber = [dataManager countOfAwaitingComments];
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

// Code for Checking a Blog configured in 1.1 supports Pages & Comments 
// When the iphone WP version upgraded from 1.1 to 1.2
- (void)checkPagesAndCommentsSupported {
	BlogDataManager *blogDataManager = [BlogDataManager sharedDataManager];
	int blogsCount = [blogDataManager countOfBlogs];
	
	for (int i = 0; i < blogsCount; i++) {
		[blogDataManager makeBlogAtIndexCurrent:i];
		NSDictionary *blog = [blogDataManager blogAtIndex:i];
		NSString *url = [blog valueForKey:@"url"];
		
		if(url != nil && [url length] >= 7 && [url hasPrefix:@"http://"]) {
			url = [url substringFromIndex:7];
		}
		
		if(url != nil && [url length]) {
			url = @"wordpress.com";
		}
		
		[Reachability sharedReachability].hostName=url;
		//Check network connectivity
		if ([[Reachability sharedReachability] internetConnectionStatus]) {
			if (![blog valueForKey:kSupportsPagesAndComments]) {
				[blogDataManager performSelectorInBackground:@selector(wrapperForSyncPagesAndCommentsForBlog:) withObject:blog];
			}
		}
	}
}

- (void)setCurrentBlog {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults objectForKey:kCurrentBlogIndex]) {
		int currentBlogIndex = [defaults integerForKey:kCurrentBlogIndex];        
        [[BlogDataManager sharedDataManager] makeBlogAtIndexCurrent:currentBlogIndex];
	} else {
        [[BlogDataManager sharedDataManager] resetCurrentBlog];
    }
}

- (void)showSplashView {
    splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, 320, 480)];
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