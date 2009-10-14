#import "WordPressAppDelegate.h"
#import "RootViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "NSString+Helpers.h"

@interface WordPressAppDelegate (Private)

- (void) checkIfStatsShouldRun;
- (void) runStats;
@end


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
	[self checkIfStatsShouldRun];
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



#pragma mark -
#pragma mark Private Methods

- (void) checkIfStatsShouldRun {
	
	//check if statsDate exists in user defaults, if not, add it and run stats since this is obviously the first time
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (![defaults objectForKey:@"statsDate"]){
		NSLog(@"not a statsDate in userdefaults");
		NSDate *theDate = [NSDate date];
		NSLog(@"date %@", theDate);
		[defaults setObject:theDate forKey:@"statsDate"];
		[self runStats];
	}else{ 
		//if statsDate existed, check if it's 7 days since last stats run, if it is > 7 days, run stats
		NSDate *statsDate = [defaults objectForKey:@"statsDate"];
		NSLog(@"statsDate %@", statsDate);
		NSDate *today = [NSDate date];
		NSTimeInterval difference = [today timeIntervalSinceDate:statsDate];
		NSTimeInterval statsInterval = 7 * 24 * 60 * 60; //number of seconds in 30 days
		//NSTimeInterval statsInterval = 1; //for testing and beta, if it's one second different, run again. will only happen on startup of app anyway...
		if (difference > statsInterval) //if it's been more than 7 days since last stats run
		{
			[self runStats];
		}
	}
}

- (void) runStats{
	//generate and post the stats data
	/*
	 - device_uuid – A unique identifier to the iPhone/iPod that the app is installed on. 
	 - app_version – the version number of the WP iPhone app
	 - language – language setting for the device. What does that look like? Is it EN or English?
	 - os_version – the version of the iPhone/iPod OS for the device
	 - num_blogs – number of blogs configured in the WP iPhone app
	 */
	NSString *deviceuuid = [[UIDevice currentDevice] uniqueIdentifier];
	
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	NSString *appversion = [info objectForKey:@"CFBundleVersion"];
	[appversion stringByUrlEncoding];
	
	NSLocale *locale = [NSLocale currentLocale];
	
	NSString *language = [locale objectForKey: NSLocaleIdentifier];
	[language stringByUrlEncoding];
	
	NSString *osversion = [[UIDevice currentDevice] systemVersion];
	[osversion stringByUrlEncoding];
	
	int num_blogs = [[BlogDataManager sharedDataManager] countOfBlogs];
	NSString *numblogs = [NSString stringWithFormat:@"%d",num_blogs];
	[numblogs stringByUrlEncoding];
	
	
	NSLog(@"UUID %@", deviceuuid);
	NSLog(@"app version %@",appversion);
	NSLog(@"language %@",language);
	NSLog(@"os_version, %@", osversion);
	NSLog(@"count of blogs %@",numblogs);
	
	//handle data coming back
	[statsData release];
	statsData = [[NSMutableData alloc] init];
	
	NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api.wordpress.org/iphoneapp/update-check/1.0/"]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:30.0];
	
	[theRequest setHTTPMethod:@"POST"];
	[theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	//create the body
	NSMutableData *postBody = [NSMutableData data];
	
	
	
	[postBody appendData:[[NSString stringWithFormat:@"device_uuid=%@&app_version=%@&language=%@&os_version=%@&num_blogs=%@", 
						   deviceuuid,
						   appversion,
						   language,
						   osversion,
						   numblogs] dataUsingEncoding:NSUTF8StringEncoding]];
	NSString *htmlStr = [[[NSString alloc] initWithData:postBody encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"htmlStr %@", htmlStr);
	[theRequest setHTTPBody:postBody];
	
	NSURLConnection *conn=[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self]autorelease];
	if (conn)   
	{  
		//NSLog(@"inside 'if conn' so connection should exist and inside else should not print to log");
	}   
	else   
	{  
		//NSLog(@"inside else - implies the 'download' could not be made");
	}  	
	
}




#pragma mark NSURLConnection callbacks

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[statsData appendData: data];
	//NSLog(@"did recieve data");
}

-(void) connection:(NSURLConnection *)connection
  didFailWithError: (NSError *)error {
	//NSLog(@"didFailWithError");
	UIAlertView *errorAlert = [[UIAlertView alloc]
							   initWithTitle: [error localizedDescription]
							   message: [error localizedFailureReason]
							   delegate:nil
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
	[errorAlert show];
	[errorAlert release];
}


- (void) connectionDidFinishLoading: (NSURLConnection*) connection {
	//NSLog(@"connectionDidFinishLoading");
	//process statsData here or call a helper method to do so.
	//it should parse the "latest version" and the over the air download url and give user some opportunity to upgrade if version numbers don't match...
	//all of this should get pulled out of WPAppDelegate and into it's own class... http request, check for stats methods, delegate methods for http, and present user with option to upgrade
	NSString *statsDataString = [[NSString alloc] initWithData:statsData encoding:NSUTF8StringEncoding];
	
	NSLog(@"should be statsDataString %@", statsDataString);
	//need to break this up based on the \n
	
	[statsDataString release];
	
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	//NSLog (@"connectionDidReceiveResponse %@", response);
}



- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:
(NSURLAuthenticationChallenge *)challenge {
	
}





- (void) handleAuthenticationOKForChallenge:
(NSURLAuthenticationChallenge *) aChallenge
								   withUser: (NSString*) username
								   password: (NSString*) password {
	
}



- (void) handleAuthenticationCancelForChallenge: (NSURLAuthenticationChallenge *) aChallenge {
	
}


@end
