#import "WordPressAppDelegate.h"
#import "RootViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"

@implementation WordPressAppDelegate

static WordPressAppDelegate *wordPressApp = NULL;

@synthesize window;
@synthesize navigationController,alertRunning;

- (id)init {
	if (!wordPressApp) {
		wordPressApp = [super init];
	}
	return wordPressApp;
}

// Initialize the singleton instance if needed and return
+ (WordPressAppDelegate *)sharedWordPressApp
{
	if (!wordPressApp)
		wordPressApp = [[WordPressAppDelegate alloc] init];
	
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
	RootViewController *rootViewController = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil];

	navigationController =	[[UINavigationController alloc] initWithRootViewController:rootViewController];
	[rootViewController release];
	// Configure and show the window
	
	navigationController.navigationBarHidden = YES;
	[window addSubview:navigationController.view];

	
	[window makeKeyAndVisible];
	
	//Code for Checking a Blog configured in 1.1 supports Pages & Comments 
	//When the iphone WP version upgraded from 1.1 to 1.2
	
		int i, blogsCount;
		BlogDataManager *blogDataManager = [BlogDataManager sharedDataManager];
		blogsCount = [blogDataManager countOfBlogs];
		for(i=0;i<blogsCount;i++)
		{
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
			if ([[Reachability sharedReachability] internetConnectionStatus])
			{
				if(![blog valueForKey:kSupportsPagesAndComments])
				{
					[blogDataManager performSelectorInBackground:@selector(wrapperForSyncPagesAndCommentsForBlog:) withObject:blog];
				}
			}
		}
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
	//[self saveBlogData];
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	[dataManager saveBlogData];

}



@end
