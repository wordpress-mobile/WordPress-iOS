
#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"

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

+ (WordPressAppDelegate *)sharedWordPressApp
{
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


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
	
	// The Reachability class is capable of notifying your application when the network
	// status changes. By default, those notifications are not enabled.
	// Comment the following line to disable them:	
    [[Reachability sharedReachability] setNetworkStatusNotificationsEnabled:YES];
    
	
	// TO-DO
	// restore state from what was saved > we need to restore the view hierarchy 
	//   Blogs > BlogDetail (modal)
	//   Blogs > Posts >Post Edit (one of 4 tabs);
	// Also Need to get currentpost and current blog from autosave area if they are there
	
	// Create the navigation and view controllers - all view controller set up happens in the loadView method
	// of the view controller
	BlogsViewController *rootViewController = [[BlogsViewController alloc] initWithStyle:UITableViewStylePlain];
    
	UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    self.navigationController = aNavigationController;
    
	[rootViewController release];
	// Configure and show the window
	
	[window addSubview:[navigationController view]];
	
	[window makeKeyAndVisible];
	
	//Code for Checking a Blog configured in 1.1 supports Pages & Comments 
	//When the iphone WP version upgraded from 1.1 to 1.2
	
	int i, blogsCount;
	BlogDataManager *blogDataManager = [BlogDataManager sharedDataManager];
	blogsCount = [blogDataManager countOfBlogs];
	for(i=0;i<blogsCount;i++) {
		//Make blog at index as current blog for updating kSyncPagesAndComments value
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
			if(![blog valueForKey:kSupportsPagesAndComments]) {
				[blogDataManager performSelectorInBackground:@selector(wrapperForSyncPagesAndCommentsForBlog:) withObject:blog];
			}
		}
	}
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int current_blog_index = [defaults integerForKey:@"current_blog_index"];
        
    if (current_blog_index > -1) {
        [[BlogDataManager sharedDataManager] makeBlogAtIndexCurrent:current_blog_index];
    }
    else {
        [[BlogDataManager sharedDataManager] resetCurrentBlog];
    }
        
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if( alertView.tag == kUnsupportedWordpressVersionTag || alertView.tag == kRSDErrorTag)
	{
		if( buttonIndex == 0 ) //Visit Site button.
		{
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://iphone.wordpress.org"]];
		}
	}
	
	self.alertRunning=NO;
}


- (void)applicationWillTerminate:(UIApplication *)application {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];

    NSString *current_blog_id = [[dataManager currentBlog] objectForKey:@"blogid"];
    NSString *current_blog_hostname = [[dataManager currentBlog] objectForKey:@"blog_host_name"];
    int current_blog_index = [dataManager indexForBlogid:current_blog_id hostName:current_blog_hostname];
        
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:current_blog_index forKey:@"current_blog_index"];

	[dataManager saveBlogData];
    
	[UIApplication sharedApplication].applicationIconBadgeNumber = [dataManager countOfAwaitingComments];
}

- (void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [splashView removeFromSuperview];
    [splashView release];
}

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

@end
