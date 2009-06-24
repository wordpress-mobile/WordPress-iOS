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
	NSLog(@"Release Candidate for Keychain Password fix :: Inside applicationDidFinishLaunching");
	
	
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
			
		
		//JOHNB:This code removes pwd from data structure and puts it into keychain
		//This code fires IF (and ONLY IF) there is a "pwd" key inside the currentBlog
		
		//if there is a "key" in "blog" that contains "pwd"
		//copy the value associated (the blog's password) to a string
		//get the other values needed from "blog" (username, url)
		//put that password string into the keychain using password, username, url
		//REMOVE the "pwd" object from the NSDictionary
		NSArray *keysFromDict = [blog allKeys];
		if ([keysFromDict containsObject:@"pwd"]){
			NSMutableDictionary *blogCopy = [[NSMutableDictionary alloc]initWithDictionary:blog];
			//get the values from blog NSDict
			NSString *passwordForKeychain = [blog valueForKey:@"pwd"];
			NSString *username = [blog valueForKey:@"username"];
			NSString *urlForKeychain = [blog valueForKey:@"url"];
			
			//check for nil or an http prefix, remove prefix if exists
			if(urlForKeychain != nil && [urlForKeychain length] >= 7 && [urlForKeychain hasPrefix:@"http://"]){
			urlForKeychain = [urlForKeychain substringFromIndex:7];
			}
			
			//log the values for debugging
			//TODO:FIXME:REMOVE THIS CODE!
			NSLog(@"passwordForKeychain = %@ username = %@ urlForKeychain = %@", passwordForKeychain, username, urlForKeychain);
			//save the password to the keychain using the necessary extra values
			[blogDataManager saveBlogPasswordToKeychain:(passwordForKeychain?passwordForKeychain:@"") andUserName:username andBlogURL:urlForKeychain];
			//remove the pwd from the data structure henceforth
			[blogCopy removeObjectForKey:@"pwd"];
			NSLog(@"Just ran: [blogCopy removeObjectForKey: @'pwd'] Saving Modified blog via setCurrentBlog as per usual");
			//save blog by using BlogDataManager setCurrentBlog - which copies the blog passed in OVER the current blog if it's different
			// compiler was unhappy with this because setCurrentBlog is a private method of the BlogDataManager class
			//So, I made a public method in BlogDataManager that just calls setCurrentBlog... avoiding the compiler error
			//it just calls setCurrentBlog and passes the exact same object (blogCopy)
			//OK - here is the call to the public method
			[blogDataManager callSetCurrentBlog:blogCopy];
			
			[blogCopy release];
			NSLog(@"inside the if... this implies we found pwd inside the blog NSDict");
		}else {
			NSLog(@"We did NOT find pwd inside the blog NSDict and thus did not go through the if");
		}
		
		//}
		// put the password into the keychain
		//remove the password "key" from the keychain
		//
		//}
		
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
	NSLog(@"Last line of applicationDidFinishLaunching");
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
	[UIApplication sharedApplication].applicationIconBadgeNumber = [dataManager countOfAwaitingComments];
}



@end
