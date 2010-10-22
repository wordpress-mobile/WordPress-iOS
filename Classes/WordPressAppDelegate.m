#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "NSString+Helpers.h"
#import "BlogViewController.h"
#import "BlogSplitViewDetailViewController.h"
#import "CPopoverManager.h"
#import "UIViewController_iPadExtensions.h"
#import "WelcomeViewController.h"

@interface WordPressAppDelegate (Private)

- (void)reachabilityChanged;
- (void)setAppBadge;
- (void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)storeCurrentBlog;
- (void)restoreCurrentBlog;
- (void)showSplashView;
- (int)indexForCurrentBlog;
- (void)passwordIntoKeychain;
- (void)checkIfStatsShouldRun;
- (void)runStats;
@end

@implementation WordPressAppDelegate

static WordPressAppDelegate *wordPressApp = NULL;

@synthesize window, currentBlog, postID;
@synthesize navigationController, alertRunning, isWPcomAuthenticated;
@synthesize splitViewController;

- (id)init {
    if (!wordPressApp) {
        wordPressApp = [super init];
		
		if (DeviceIsPad())
			[UIViewController youWillAutorotateOrYouWillDieMrBond];
		
        dataManager = [BlogDataManager sharedDataManager];
		
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_authenticated_flag"] != nil) {
			NSString *tempIsAuthenticated = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_authenticated_flag"];
			if([tempIsAuthenticated isEqualToString:@"1"])
				self.isWPcomAuthenticated = YES;
		}
		
		NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
		[[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"version_preference"];
		
		[self performSelectorInBackground:@selector(checkWPcomAuthentication) withObject:nil];
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
	[postID release];
    [navigationController release];
    [window release];
    [dataManager release];
	[currentBlog release];
    [super dealloc];
}

#pragma mark -
#pragma mark UIApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[self checkIfStatsShouldRun];
	
	if(getenv("NSZombieEnabled"))
		NSLog(@"NSZombieEnabled!");
	else if(getenv("NSAutoreleaseFreedObjectCheckEnabled"))
		NSLog(@"NSAutoreleaseFreedObjectCheckEnabled enabled!");

    [[Reachability sharedReachability] setNetworkStatusNotificationsEnabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];

	[self setAutoRefreshMarkers];
	[self passwordIntoKeychain];
	[self restoreCurrentBlog];
	
	NSManagedObjectContext *context = [self managedObjectContext];
    if (!context) {
        NSLog(@"\nCould not create *context for self");
    }
	
	BlogsViewController *blogsViewController = [[BlogsViewController alloc] initWithStyle:UITableViewStylePlain];
	if(DeviceIsPad() == NO)
	{
		UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:blogsViewController];
		self.navigationController = aNavigationController;

		[window addSubview:[navigationController view]];

		if ([self shouldLoadBlogFromUserDefaults]) {
			[blogsViewController showBlog:NO];
		}

		if ([dataManager countOfBlogs] == 0) {
			WelcomeViewController *wViewController = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:[NSBundle mainBundle]];
			[blogsViewController.navigationController pushViewController:wViewController animated:YES];
			[wViewController release];
		}
		else {
			blogsViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Blogs" style:UIBarButtonItemStyleBordered target:nil action:nil];
		}
	}
	else
	{
		[window addSubview:splitViewController.view];
		[window makeKeyAndVisible];

		if ([dataManager countOfBlogs] == 0)
		{
			WelcomeViewController *welcomeViewController = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController-iPad" bundle:nil];
			UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];
			aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
			aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
			self.navigationController = aNavigationController;
			[splitViewController presentModalViewController:aNavigationController animated:YES];
			[aNavigationController release];
			[welcomeViewController release];
		}
		else if ([dataManager countOfBlogs] == 1)
		{
			[dataManager makeBlogAtIndexCurrent:0];
		}

		//NSLog(@"? %d", [self.splitViewController shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeLeft]);

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newBlogNotification:) name:@"NewBlogAdded" object:nil];
		[self performSelector:@selector(showPopoverIfNecessary) withObject:nil afterDelay:0.1];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deleteLocalDraft:)
												 name:@"LocalDraftWasPublishedSuccessfully" object:nil];
	
	// Check for pending crash reports
	PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
	NSError *error;
	
	// Check if we previously crashed
	if ([crashReporter hasPendingCrashReport])
		[self handleCrashReport];
    
	// Enable the Crash Reporter
	if (![crashReporter enableCrashReporterAndReturnError: &error])
		NSLog(@"Warning: Could not enable crash reporter: %@", error);
	
	[blogsViewController release];
	[window makeKeyAndVisible];
}

- (void)handleCrashReport {
	PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
	NSData *crashData;
	NSError *error;
	
	// Try loading the crash report
	crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
	if (crashData == nil) {
		NSLog(@"Could not load crash report: %@", error);
		[crashReporter purgePendingCrashReport];
	}
	
	// We could send the report from here, but we'll just print out
	// some debugging info instead
	PLCrashReport *report = [[[PLCrashReport alloc] initWithData: crashData error: &error] autorelease];
	if (report == nil) {
		NSLog(@"Could not parse crash report");
		[crashReporter purgePendingCrashReport];
	}
	else {
		UIAlertView *crashAlert = [[UIAlertView alloc] initWithTitle:@"Crash Detected" 
															 message:@"It looks like WordPress crashed the last time you used it. Would you like to help us resolve the issue by sending a crash report?" 
															delegate:self
												   cancelButtonTitle:@"No Thanks"
												   otherButtonTitles:@"Sure", nil];
		crashAlert.tag = kCrashAlertTag;
		[crashAlert show];
		[crashAlert release];
	}
	
	return;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [dataManager saveBlogData];
    [self setAppBadge];
	
	if (DeviceIsPad()) {
		UIViewController *topVC = self.masterNavigationController.topViewController;
		if (topVC && [topVC isKindOfClass:[BlogViewController class]]) {
			[(BlogViewController *)topVC saveState];
		}
	}
}

#pragma mark -
#pragma mark Public Methods

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
	NSLog(@"Showing alert with title: %@", message);
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

- (void)showContentDetailViewController:(UIViewController *)viewController {
	if (self.splitViewController) {
		UINavigationController *navController = self.detailNavigationController;
		// preserve left bar button item: issue #379
		viewController.navigationItem.leftBarButtonItem = navController.topViewController.navigationItem.leftBarButtonItem;
		[navController setViewControllers:[NSArray arrayWithObject:viewController] animated:NO];
	}
	else if (self.navigationController) {
		[self.navigationController pushViewController:viewController animated:YES];
	}
}

- (void)syncBlogs {
	[dataManager performSelectorInBackground:@selector(syncBlogsInBackground) withObject:nil];
}

- (void)syncBlogCategoriesAndStatuses {
	if(dataManager.countOfBlogs > 0) {
		[dataManager performSelectorInBackground:@selector(syncBlogCategoriesAndStatuses) withObject:nil];
	}
}

- (void)startSyncTimer {
	NSThread *syncThread = [[NSThread alloc] initWithTarget:self selector:@selector(startSyncTimerThread) object:nil];
	[syncThread start];
	[syncThread release];
}

- (void)startSyncTimerThread {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSTimer *syncTimer = [NSTimer timerWithTimeInterval:600.0
											 target:self
										   selector:@selector(syncTick:)
										   userInfo:nil
											repeats:YES];
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	[runLoop addTimer:syncTimer forMode:NSRunLoopCommonModes];
	[runLoop run];
	
	[pool release];
}

- (void)syncTick:(NSTimer *)timer {
	[dataManager syncBlogs];
}

- (void)deleteLocalDraft:(NSNotification *)notification {
	NSString *uniqueID = [notification object];
	
	if(uniqueID != nil) {
		NSLog(@"deleting local draft: %@", uniqueID);
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:self.managedObjectContext];   
		NSFetchRequest *request = [[NSFetchRequest alloc] init];  
		[request setEntity:entity];   
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateModified" ascending:NO];  
		NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];  
		[request setSortDescriptors:sortDescriptors];  
		[sortDescriptor release];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(uniqueID == %@)", uniqueID];
		[request setPredicate:predicate];
		NSError *error;  
		NSMutableArray *postsToDelete = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];   
		
		if (!postsToDelete) {  
			// Bad. Srsly.
		}
		
		for (NSManagedObject *post in postsToDelete) {
			[self.managedObjectContext deleteObject:post];
		}
		
		if (![self.managedObjectContext save:&error]) {
			NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
			exit(-1);
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DraftsUpdated" object:nil];
		[postsToDelete release];
		[request release];
	}
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"WordPress" ofType:@"mom"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"WordPress.sqlite"]];
	
	// This is important for automatic version migration. Leave it here!
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	
	NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
		NSLog(@"Error opening the database. Deleting the file and trying again.");
		
		//delete the sqlite file and try again
		[[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:nil];
		if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
		
		//if the app did not quit, show the alert to inform the users that the data have been deleted
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error establishing database connection." 
														 message:@"Please delete the app and reinstall." 
														delegate:nil 
											   cancelButtonTitle:@"OK" 
											   otherButtonTitles:nil] autorelease];
		[alert show];
    }    
    
    return persistentStoreCoordinator_;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
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
	else if(alertView.tag == kCrashAlertTag) {
		// User confirmed send crash report
		if(buttonIndex == 1) {
			PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
			NSError *error;
			NSData *crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
			if(crashData != nil) {
				PLCrashReport *report = [[[PLCrashReport alloc] initWithData:crashData error: &error] autorelease];
				if (report == nil) {
					NSLog(@"Could not parse crash report");
				}
				else {
					// Create a mail message with the crash report
					MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
					NSString *subject = [NSString stringWithFormat:@"WordPress %@ Crash Report", 
							 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
					[controller setMailComposeDelegate:self];
					[controller setSubject:subject];
					[controller setMessageBody:@"Please see the attached crash report." isHTML:NO];
					[controller addAttachmentData:crashData mimeType:@"text/html" fileName:@"crash.log"];
					[self.navigationController presentModalViewController:controller animated:YES];
					[controller release];
				}
			}
			
			[crashReporter purgePendingCrashReport];
		}
	}

    self.alertRunning = NO;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error  {    
    [[controller parentViewController] dismissModalViewControllerAnimated:YES];
}

- (void)setAppBadge {
    [UIApplication sharedApplication].applicationIconBadgeNumber = [dataManager countOfAwaitingComments];
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

- (void)checkWPcomAuthentication {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *authURL = @"https://wordpress.com/xmlrpc.php";
	
	if(([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"] != nil) && 
	   ([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_password_preference"] != nil)) {
		isWPcomAuthenticated = [[WPDataController sharedInstance] authenticateUser:authURL 
		  username:[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"]
		  password:[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_password_preference"]];
	}
	else {
		isWPcomAuthenticated = NO;
	}
	
	if(isWPcomAuthenticated)
		[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"wpcom_authenticated_flag"];
	else
		[[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"wpcom_authenticated_flag"];
	
	[pool release];
}

- (int)indexForCurrentBlog {
    return [dataManager indexForBlogid:[[dataManager currentBlog] objectForKey:kBlogId] 
								   url:[[dataManager currentBlog] objectForKey:@"url"]];
}

- (void)storeCurrentBlog {
    if([dataManager currentBlog])
        [[NSUserDefaults standardUserDefaults] setInteger:[self indexForCurrentBlog] forKey:kCurrentBlogIndex];
    else
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentBlogIndex];
}

- (void)restoreCurrentBlog {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kCurrentBlogIndex]) {
        int currentBlogIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kCurrentBlogIndex];
        if (currentBlogIndex >= 0) 
            [dataManager makeBlogAtIndexCurrent:currentBlogIndex];
    }
    else
        [dataManager resetCurrentBlog];
}

- (void)showSplashView {
    splashView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    splashView.image = [UIImage imageNamed:@"Default.png"];
    [window addSubview:splashView];
    [window bringSubviewToFront:splashView];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:window cache:YES];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(startupAnimationDone:finished:context:)];
    splashView.alpha = 0.0;
//    splashView.frame = CGRectInset(splashView.bounds, -60, -60);
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
	//[defaults setObject:nil forKey:@"statsDate"];  // Uncomment this line to force stats.
	if (![defaults objectForKey:@"statsDate"]){
		NSDate *theDate = [NSDate date];
		[defaults setObject:theDate forKey:@"statsDate"];
		[self runStats];
	}else{
		//if statsDate existed, check if it's 7 days since last stats run, if it is > 7 days, run stats
		NSDate *statsDate = [defaults objectForKey:@"statsDate"];
		NSDate *today = [NSDate date];
		NSTimeInterval difference = [today timeIntervalSinceDate:statsDate];
		NSTimeInterval statsInterval = 7 * 24 * 60 * 60; //number of seconds in 30 days
		if (difference > statsInterval) //if it's been more than 7 days since last stats run
		{
			[self runStats];
		}
	}
}

- (void)runStats {
	//generate and post the stats data
	/*
	 - device_uuid – A unique identifier to the iPhone/iPod that the app is installed on.
	 - app_version – the version number of the WP iPhone app
	 - language – language setting for the device. What does that look like? Is it EN or English?
	 - os_version – the version of the iPhone/iPod OS for the device
	 - num_blogs – number of blogs configured in the WP iPhone app
	 - device_model - kind of device on which the WP iPhone app is installed
	 */
	
	NSString *deviceModel = [[[UIDevice currentDevice] platformString] stringByUrlEncoding];
	NSString *deviceuuid = [[UIDevice currentDevice] uniqueIdentifier];
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	NSString *appversion = [[info objectForKey:@"CFBundleVersion"] stringByUrlEncoding];
	NSLocale *locale = [NSLocale currentLocale];
	NSString *language = [[locale objectForKey: NSLocaleIdentifier] stringByUrlEncoding];
	NSString *osversion = [[[UIDevice currentDevice] systemVersion] stringByUrlEncoding];
	int num_blogs = [[BlogDataManager sharedDataManager] countOfBlogs];
	NSString *numblogs = [[NSString stringWithFormat:@"%d", num_blogs] stringByUrlEncoding];
	
	//NSLog(@"UUID %@", deviceuuid);
	//NSLog(@"app version %@",appversion);
	//NSLog(@"language %@",language);
	//NSLog(@"os_version, %@", osversion);
	//NSLog(@"count of blogs %@",numblogs);
	//NSLog(@"device_model: %@", deviceModel);
	
	//handle data coming back
	// ** TODO @frsh: This needs to be completely redone with a custom helper class. ***
	[statsData release];
	statsData = [[NSMutableData alloc] init];
	
	NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api.wordpress.org/iphoneapp/update-check/1.0/"]
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:30.0];
	
	[theRequest setHTTPMethod:@"POST"];
	[theRequest addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
	//create the body
	NSMutableData *postBody = [NSMutableData data];
	
	[postBody appendData:[[NSString stringWithFormat:@"device_uuid=%@&app_version=%@&language=%@&os_version=%@&num_blogs=%@&device_model=%@",
						   deviceuuid,
						   appversion,
						   language,
						   osversion,
						   numblogs,
						   deviceModel] dataUsingEncoding:NSUTF8StringEncoding]];
	
	//NSString *htmlStr = [[[NSString alloc] initWithData:postBody encoding:NSUTF8StringEncoding] autorelease];
	[theRequest setHTTPBody:postBody];
	
	NSURLConnection *conn = [[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
	if(conn){
		// This is just to keep Analyzer from complaining.
	}
}

#pragma mark -
#pragma mark NSURLConnection callbacks

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[statsData appendData: data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError: (NSError *)error {
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
	NSString *statsDataString = [[NSString alloc] initWithData:statsData encoding:NSUTF8StringEncoding];
	[statsDataString release];

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {

}

- (void) handleAuthenticationOKForChallenge:(NSURLAuthenticationChallenge *)aChallenge withUser:(NSString*)username password:(NSString*)password {

}

- (void) handleAuthenticationCancelForChallenge: (NSURLAuthenticationChallenge *)aChallenge {

}

#pragma mark -
#pragma mark Split View

- (UINavigationController *)masterNavigationController {
	id theObject = [self.splitViewController.viewControllers objectAtIndex:0];
	NSAssert([theObject isKindOfClass:[UINavigationController class]], @"That is not a nav controller");
	return(theObject);
}

- (UINavigationController *)detailNavigationController {
	id theObject = [self.splitViewController.viewControllers objectAtIndex:1];
	NSAssert([theObject isKindOfClass:[UINavigationController class]], @"That is not a nav controller");
	return(theObject);
}

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc {
	UINavigationItem *theNavigationItem = [[self.detailNavigationController.viewControllers objectAtIndex:0] navigationItem];
	[barButtonItem setTitle:@"My Blog"];
	[theNavigationItem setLeftBarButtonItem:barButtonItem animated:YES];
	if ([[self.detailNavigationController.viewControllers objectAtIndex:0] isKindOfClass:[BlogSplitViewDetailViewController class]])
	{
		[[CPopoverManager instance] setCurrentPopoverController:pc];
	}
}

- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	[[[self.detailNavigationController.viewControllers objectAtIndex:0] navigationItem] setLeftBarButtonItem:NULL animated:YES];

	[[CPopoverManager instance] setCurrentPopoverController:NULL];
}

- (void)splitViewController: (UISplitViewController*)svc popoverController: (UIPopoverController*)pc willPresentViewController:(UIViewController *)aViewController {
}

- (void)showPopoverIfNecessary {
	if (UIInterfaceOrientationIsPortrait(self.masterNavigationController.interfaceOrientation) && !self.splitViewController.modalViewController) {
		UINavigationItem *theNavigationItem = [[self.detailNavigationController.viewControllers objectAtIndex:0] navigationItem];
		[[[CPopoverManager instance] currentPopoverController] presentPopoverFromBarButtonItem:theNavigationItem.leftBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		[[[CPopoverManager instance] currentPopoverController] dismissPopoverAnimated:NO];
	}
}

- (void)newBlogNotification:(NSNotification *)aNotification {
	if (UIInterfaceOrientationIsPortrait(self.masterNavigationController.interfaceOrientation)) {
		UINavigationItem *theNavigationItem = [[self.detailNavigationController.viewControllers objectAtIndex:0] navigationItem];
		[[[CPopoverManager instance] currentPopoverController] presentPopoverFromBarButtonItem:theNavigationItem.leftBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
}


@end
