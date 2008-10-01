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
	
	WPLog(@"Launching Wordpress....");
	
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
	
	
	WPLog(@"end of method applicationDidFinishLaunching");
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
}


- (void)applicationWillTerminate:(UIApplication *)application {
	//[self saveBlogData];
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	[dataManager saveBlogData];

}



@end
