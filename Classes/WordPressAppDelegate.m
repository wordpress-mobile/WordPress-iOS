#import "WordPressAppDelegate.h"

#import "BlogsViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "NSString+Helpers.h"

@interface WordPressAppDelegate (Private)

- (void)reachabilityChanged;
- (void)setAppBadge;
- (void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)checkPagesAndCommentsSupported;
- (void)storeCurrentBlog;
- (void)restoreCurrentBlog;
- (void)showSplashView;
- (int)indexForCurrentBlog;
- (void) passwordIntoKeychain;
- (void) checkIfStatsShouldRun;
- (void) runStats;
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
#pragma mark UIApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[self checkIfStatsShouldRun];
	
    [[Reachability sharedReachability] setNetworkStatusNotificationsEnabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];

    BlogsViewController *blogsViewController = [[BlogsViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:blogsViewController];
    self.navigationController = aNavigationController;
    
    [window addSubview:[navigationController view]];
    [window makeKeyAndVisible];

	[self setAutoRefreshMarkers];
    [self checkPagesAndCommentsSupported];
	[self passwordIntoKeychain];
    [self restoreCurrentBlog];
    
    if ([self shouldLoadBlogFromUserDefaults]) {
        [blogsViewController showBlog:NO];
    }
    
    if ([dataManager countOfBlogs] == 0) {
        [blogsViewController showBlogDetailModalViewForNewBlogWithAnimation:NO];
    }
    
    [blogsViewController release];
        
    [self showSplashView];
	
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [dataManager saveBlogData];
    [self setAppBadge];
}

#pragma mark -
#pragma mark Public Methods

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

- (void)setAutoRefreshMarkers {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
	[defaults setBool:true forKey:@"refreshCommentsRequired"];
	[defaults setBool:true forKey:@"refreshPostsRequired"];
	[defaults setBool:true forKey:@"refreshPagesRequired"];
	[defaults setBool:true forKey:@"anyMorePosts"];
	[defaults setBool:true forKey:@"anyMorePages"];
}

#pragma mark -
#pragma mark Private Methods

- (void)reachabilityChanged {
    connectionStatus = ([[Reachability sharedReachability] remoteHostStatus] != NotReachable);
}

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

        // Check network connectivity.
        if ([[Reachability sharedReachability] internetConnectionStatus]) {
            if (![blog valueForKey:kSupportsPagesAndComments]) {
                [dataManager performSelectorInBackground:@selector(wrapperForSyncPagesAndCommentsForBlog:) withObject:blog];
            }
        }
    }
}

- (void)resetCurrentBlogInUserDefaults {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:kCurrentBlogIndex];
}

- (BOOL)shouldLoadBlogFromUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([self indexForCurrentBlog] == [defaults integerForKey:kCurrentBlogIndex]) {
        return YES;
    }
    return NO;
}

- (int)indexForCurrentBlog {
    NSDictionary *currentBlog = [dataManager currentBlog];
    NSString *currentBlogId = [currentBlog objectForKey:kBlogId];
    NSString *currentBlogHostName = [currentBlog objectForKey:kBlogHostName];
    return [dataManager indexForBlogid:currentBlogId hostName:currentBlogHostName];
}

- (void)storeCurrentBlog {
    NSDictionary *currentBlog = [dataManager currentBlog];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (currentBlog) {        
        [defaults setInteger:[self indexForCurrentBlog] forKey:kCurrentBlogIndex];
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

- (void) passwordIntoKeychain {
	//Code for Checking a Blog configured in 1.1 supports Pages & Comments 
	//When the iphone WP version upgraded from 1.1 to 1.2
	
	int i, blogsCount;
	BlogDataManager *blogDataManager = [BlogDataManager sharedDataManager];
	blogsCount = [blogDataManager countOfBlogs];
	for(i=0;i<blogsCount;i++)
	{
		//Make blog at index as current blog for checking presence of password in datastructure instead of keychain
		//this should only happen when migrating from an old version that stored password in data strucutre into this new
		//version that stores it into keychain.  Ultimately (after a year or so?) we can probably remove this code entirely
		//since everyone should be upgraded by then
		[blogDataManager makeBlogAtIndexCurrent:i];
		NSDictionary *blog = [blogDataManager blogAtIndex:i];
	/*	NSString *url = [blog valueForKey:@"url"];
		
		if(url != nil && [url length] >= 7 && [url hasPrefix:@"http://"]) {
			url = [url substringFromIndex:7];
		}
		
		if(url != nil && [url length]) {
			url = @"wordpress.com";
		}
	*/	
		
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
			//NSLog(@"passwordForKeychain = %@ username = %@ urlForKeychain = %@", passwordForKeychain, username, urlForKeychain);
			//save the password to the keychain using the necessary extra values
			[blogDataManager saveBlogPasswordToKeychain:(passwordForKeychain?passwordForKeychain:@"") andUserName:username andBlogURL:urlForKeychain];
			//remove the pwd from the data structure henceforth
			//NSLog(@"before removeObjectForKey");
			//NSLog(@"This is the value before the remove %@", [blogCopy objectForKey:@"pwd"]);
			[blogCopy removeObjectForKey:@"pwd"];
			//[blogCopy setObject:@"asdf" forKey:@"pwd"];
			//NSLog(@"Just ran: [blogCopy removeObjectForKey: @'pwd'] Saving Modified blog via setCurrentBlog as per usual");
			//NSLog(@"after removeObjectForKey");
			//NSLog(@"This is the value after the remove %@", [blogCopy objectForKey:@"pwd"]);
			//save blog by using BlogDataManager setCurrentBlog - which copies the blog passed in OVER the current blog if it's different
			// compiler was unhappy with this because setCurrentBlog is a private method of the BlogDataManager class
			//So, I made a public method in BlogDataManager that just calls setCurrentBlog... avoiding the compiler error
			//it just calls setCurrentBlog and passes the exact same object (blogCopy)
			//OK - here is the call to the public method
			
			//[blogDataManager 
			
			[blogDataManager replaceBlogWithBlog:blogCopy atIndex:i];
			//JOHNB - I think this is unnecessary now that we have replaceBLogWithBlog
			
			//[blogDataManager callSetCurrentBlog:blogCopy];
			
			[blogCopy release];
			//NSLog(@"inside the if... this implies we found pwd inside the blog NSDict");
		}else {
			//NSLog(@"We did NOT find pwd inside the blog NSDict and thus did not go through the if");
		}
}
}

- (void) checkIfStatsShouldRun {
	
	//check if statsDate exists in user defaults, if not, add it and run stats since this is obviously the first time
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (![defaults objectForKey:@"statsDate"]){
		//NSLog(@"not a statsDate in userdefaults");
		NSDate *theDate = [NSDate date];
		//NSLog(@"date %@", theDate);
		[defaults setObject:theDate forKey:@"statsDate"];
		[self runStats];
	}else{ 
		//if statsDate existed, check if it's 7 days since last stats run, if it is > 7 days, run stats
		NSDate *statsDate = [defaults objectForKey:@"statsDate"];
		//NSLog(@"statsDate %@", statsDate);
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
	 
	 NSString *deviceType = [UIDevice currentDevice].model;
	 if([deviceType isEqualToString:@"iPhone"])
	 // it's an iPhone
	 
	 NSString *deviceType = [UIDevice currentDevice].model;
	 NSLog(@"device string from currentDevice.model %@", deviceType);
	 
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
	
	
	//NSLog(@"UUID %@", deviceuuid);
	//NSLog(@"app version %@",appversion);
	//NSLog(@"language %@",language);
	//NSLog(@"os_version, %@", osversion);
	//NSLog(@"count of blogs %@",numblogs);
	
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
