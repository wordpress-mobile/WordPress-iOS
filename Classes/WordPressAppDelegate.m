#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"
#import "WPReachability.h"
#import "NSString+Helpers.h"
#import "BlogViewController.h"
#import "BlogSplitViewDetailViewController.h"
#import "CPopoverManager.h"
#import "UIViewController_iPadExtensions.h"
#import "WelcomeViewController.h"
#import "BetaUIWindow.h"
#import "MigrateBlogsFromFiles.h"

@interface WordPressAppDelegate (Private)

- (void)reachabilityChanged;
- (void)setAppBadge;
- (void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)showSplashView;
- (void)checkIfStatsShouldRun;
- (void)runStats;
@end

NSString *CrashFilePath() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"crash_data.txt"];
}

NSUncaughtExceptionHandler *defaultExceptionHandler;
void uncaughtExceptionHandler(NSException *exception) {
    NSArray *backtrace = [exception callStackSymbols];
    NSString *platform = [[UIDevice currentDevice] platform];
    NSString *version = [[UIDevice currentDevice] systemVersion];
    NSString *message = [NSString stringWithFormat:@"device: %@. os: %@. backtrace:\n%@",
                         platform,
                         version,
                         backtrace];
    NSLog(@"Logging error (%@|%@): %@\n%@", platform, version, [exception reason], backtrace);

    NSString *ourCrash = [NSString stringWithFormat:@"Logging error (%@|%@): %@\n%@", platform, version, [exception reason], backtrace];
    [ourCrash writeToFile:CrashFilePath() atomically:NO];

    [FlurryAPI logError:@"Uncaught" message:message exception:exception];
	defaultExceptionHandler(exception);
}

@implementation WordPressAppDelegate

static WordPressAppDelegate *wordPressApp = NULL;

@synthesize window, currentBlog, postID;
@synthesize navigationController, alertRunning, isWPcomAuthenticated;
@synthesize splitViewController, crashReportView;

- (id)init {
    if (!wordPressApp) {
        wordPressApp = [super init];
		
		if (DeviceIsPad())
			[UIViewController youWillAutorotateOrYouWillDieMrBond];
				
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
	[crashReportView release];
	[postID release];
    [navigationController release];
    [window release];
	[currentBlog release];
    [super dealloc];
}

#pragma mark -
#pragma mark UIApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	// Check for pending crash reports
	PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
	NSError *error;
	
	// Check if we previously crashed
	if ([crashReporter hasPendingCrashReport])
		[self handleCrashReport];
    
	// Enable the Crash Reporter
	if (![crashReporter enableCrashReporterAndReturnError: &error])
		NSLog(@"Warning: Could not enable crash reporter: %@", error);
	
    defaultExceptionHandler = NSGetUncaughtExceptionHandler();
	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
	
#ifndef DEBUG
#warning Need Flurry api key for distribution
#endif
    [FlurryAPI startSession:@"NPFZWR9J1MI9QU1ICU9H"]; // FIXME: set up real api key for distribution
	[FlurryAPI setSessionReportsOnPauseEnabled:YES];

	
	if(getenv("NSZombieEnabled"))
		NSLog(@"NSZombieEnabled!");
	else if(getenv("NSAutoreleaseFreedObjectCheckEnabled"))
		NSLog(@"NSAutoreleaseFreedObjectCheckEnabled enabled!");

	
	// Set current directory for WordPress app
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *currentDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"wordpress"];
	
	BOOL isDir;
	
	if (![fileManager fileExistsAtPath:currentDirectoryPath isDirectory:&isDir] || !isDir) {
		[fileManager createDirectoryAtPath:currentDirectoryPath attributes:nil];
	}
	//FIXME: we should handle errors here:
	/*
	 NSError *error;
	 BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:currentDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error];
	 if (!success) {
	 NSLog(@"Error creating data path: %@", [error localizedDescription]);
	 }
	 */
	
	// set the current dir
	[fileManager changeCurrentDirectoryPath:currentDirectoryPath];

	
    [[WPReachability sharedReachability] setNetworkStatusNotificationsEnabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];

	[self setAutoRefreshMarkers];
	
	NSManagedObjectContext *context = [self managedObjectContext];
    if (!context) {
        NSLog(@"\nCould not create *context for self");
    }
	// Stats use core data, so run them after initialization
	[self checkIfStatsShouldRun];
	
	BlogsViewController *blogsViewController = [[BlogsViewController alloc] initWithStyle:UITableViewStylePlain];
	crashReportView = [[CrashReportViewController alloc] initWithNibName:@"CrashReportView" bundle:nil];
	
	//BETA FEEDBACK BAR, COMMENT THIS OUT BEFORE RELEASE
	BetaUIWindow *betaWindow = [[BetaUIWindow alloc] initWithFrame:CGRectZero];
	betaWindow.hidden = NO;
	//BETA FEEDBACK BAR
	
	if(DeviceIsPad() == NO)
	{
		UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:blogsViewController];
        //aNavigationController.navigationBar.tintColor = [UIColor colorWithRed:31/256.0 green:126/256.0 blue:163/256.0 alpha:1.0];
		self.navigationController = aNavigationController;

		[window addSubview:[navigationController view]];

		if ([Blog countWithContext:context] == 0) {
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

		if ([Blog countWithContext:context] == 0)
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

		//NSLog(@"? %d", [self.splitViewController shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeLeft]);

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newBlogNotification:) name:@"NewBlogAdded" object:nil];
		[self performSelector:@selector(showPopoverIfNecessary) withObject:nil afterDelay:0.1];
	}
	
	// Add listeners
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deleteLocalDraft:)
												 name:@"LocalDraftWasPublishedSuccessfully" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dismissCrashReporter:)
												 name:@"CrashReporterIsFinished" object:nil];
	
	
	//listener for XML-RPC errors
	//in the future we could put the errors message in a dedicated screen that users can bring to front when samething went wrong, and can take a look at the error msg.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:kXML_RPC_ERROR_OCCURS object:nil];
	//TODO: we should add a screen? in which print the error msgs that are from async uploading errors --> PostUploadFailed
	
	// another notification message came from comments --> CommentUploadFailed
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:@"CommentUploadFailed" object:nil];
	
	[blogsViewController release];
	[window makeKeyAndVisible];
	
	// Register for push notifications
	/*[[UIApplication sharedApplication]
	 registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
										 UIRemoteNotificationTypeSound |
										 UIRemoteNotificationTypeAlert)];*/
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
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"crash_report_dontbug"] == nil) {
			// Display CrashReportViewController
			if(!DeviceIsPad())
				[self.navigationController pushViewController:crashReportView animated:YES];
		}
		else {
			[crashReporter purgePendingCrashReport];
		}
	}
	
	return;
}

- (void)dismissCrashReporter:(NSNotification *)notification {
	if(DeviceIsPad()) {
		[splitViewController dismissModalViewControllerAnimated:NO];
		crashReportView.view.frame = CGRectMake(0, 1000, 0, 0);
		[crashReportView.view removeFromSuperview];
	}
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self setAppBadge];
	
	if (DeviceIsPad()) {
		UIViewController *topVC = self.masterNavigationController.topViewController;
		if (topVC && [topVC isKindOfClass:[BlogViewController class]]) {
			[(BlogViewController *)topVC saveState];
		}
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self applicationWillTerminate:application];
}

#pragma mark -
#pragma mark Public Methods

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
	WPLog(@"Showing alert with title: %@", message);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                          message:message
                          delegate:self
						cancelButtonTitle:@"Need Help?"
						otherButtonTitles:@"OK", nil];
    [alert show];
    [alert release];
}

- (void)showErrorAlert:(NSString *)message {
    [self showAlertWithTitle:@"Error" message:message];
}

- (void)showNotificationErrorAlert:(NSNotification *)notification {
	NSString *cleanedErrorMsg = nil;
	
	if([[notification object] isKindOfClass:[NSError class]]) {
		
		NSError *err  = (NSError *)[notification object];
		cleanedErrorMsg = [err localizedDescription];
		
		//org.wordpress.iphone --> XML-RPC errors
		if ([[err domain] isEqualToString:@"org.wordpress.iphone"]){
			if([err code] == 401)
				cleanedErrorMsg = @"Sorry, you cannot access this feature. Please check your User Role on this blog.";
		}
		
	} else {
		cleanedErrorMsg  = (NSString *)[notification object];
	}
	
	if([cleanedErrorMsg rangeOfString:@"NSXMLParserErrorDomain"].location != NSNotFound )
		cleanedErrorMsg = @"The app can't recognize the server response. Please, check the configuration of your blog.";
	
	[self showAlertWithTitle:@"Error" message:cleanedErrorMsg];
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
        if (viewController) {
            [navController setViewControllers:[NSArray arrayWithObject:viewController] animated:NO];
        } else {
            UIImageView *fabric = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fabric"]];
            UIViewController *fabricController = [[UIViewController alloc] init];
            fabricController.view = fabric;
            fabricController.navigationItem.title = @"WordPress";
            fabricController.navigationItem.leftBarButtonItem = navController.topViewController.navigationItem.leftBarButtonItem;
            [navController setViewControllers:[NSArray arrayWithObject:fabricController] animated:NO];
            [fabric release];
            [fabricController release];
        }

	}
	else if (self.navigationController) {
		[self.navigationController pushViewController:viewController animated:YES];
	}
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
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"WordPress" ofType:@"momd"];
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
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, nil];
	
	NSError *error = nil;
	
// The following conditional code is meant to test the detection of mapping model for migrations
// It should remain disabled unless you are debugging why migrations aren't run
#if FALSE
	WPFLog(@"Debugging migration detection");
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
																							  URL:storeURL
																							error:&error];
	if (sourceMetadata == nil) {
		WPFLog(@"Can't find source persistent store");
	} else {
		WPFLog(@"Source store: %@", sourceMetadata);
	}
	NSManagedObjectModel *destinationModel = [self managedObjectModel];
	BOOL pscCompatibile = [destinationModel
						   isConfiguration:nil
						   compatibleWithStoreMetadata:sourceMetadata];
	if (pscCompatibile) {
		WPFLog(@"No migration needed");
	} else {
		WPFLog(@"Migration needed");
	}
	NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:sourceMetadata];
	if (sourceModel != nil) {
		WPFLog(@"source model found");
	} else {
		WPFLog(@"source model not found");
	}

	NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel
																 destinationModel:destinationModel];
	//WPFLog(@"Bundle contents: %@", [[NSBundle mainBundle] pathsForResourcesOfType:@"cdm" inDirectory:nil]);
	NSMappingModel *mappingModel = [NSMappingModel mappingModelFromBundles:[NSArray arrayWithObject:[NSBundle mainBundle]]
															forSourceModel:sourceModel
														  destinationModel:destinationModel];
	if (mappingModel != nil) {
		WPFLog(@"mapping model found");
	} else {
		WPFLog(@"mapping model not found");
	}

	if (NO) {
		BOOL migrates = [manager migrateStoreFromURL:storeURL
												type:NSSQLiteStoreType
											 options:nil
									withMappingModel:mappingModel
									toDestinationURL:storeURL
									 destinationType:NSSQLiteStoreType
								  destinationOptions:nil
											   error:&error];

		if (migrates) {
			WPFLog(@"migration went OK");
		} else {
			WPFLog(@"migration failed: %@", [error localizedDescription]);
		}
	}
	
	WPFLog(@"End of debugging migration detection");
#endif
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
		WPFLog(@"Error opening the database. %@\nDeleting the file and trying again", error);
#ifdef DEBUGMODE 
		// Don't delete the database on debug builds
		// Makes migration debugging less of a pain
		abort();
#endif
		
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
    } else {
		// If there are no blogs and blogs.archive still exists, force import of blogs
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *currentDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"wordpress"];
		NSString *blogsArchiveFilePath = [currentDirectoryPath stringByAppendingPathComponent:@"blogs.archive"];
		if ([fileManager fileExistsAtPath:blogsArchiveFilePath]) {
			NSManagedObjectContext *destMOC = [[NSManagedObjectContext alloc] init];
			[destMOC setPersistentStoreCoordinator:persistentStoreCoordinator_];

			MigrateBlogsFromFiles *blogMigrator = [[MigrateBlogsFromFiles alloc] init];
			[blogMigrator forceBlogsMigrationInContext:destMOC error:&error];
			[blogMigrator release];
			if (![destMOC save:&error]) {
				WPFLog(@"Error saving blogs-only migration: %@", error);
			}
			[destMOC release];
			[fileManager removeItemAtPath:blogsArchiveFilePath error:&error];
		}
	}
	[[FileLogger sharedInstance] flush];
    
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
    connectionStatus = ([[WPReachability sharedReachability] remoteHostStatus] != NotReachable);
}

- (void)setAppBadge {
    //[UIApplication sharedApplication].applicationIconBadgeNumber = [dataManager countOfAwaitingComments];
}

- (void)checkWPcomAuthentication {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *authURL = @"https://wordpress.com/xmlrpc.php";
	
    NSError *error = nil;
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"] != nil) {
        NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_password_preference"] != nil) {
            // Migrate password to keychain
            [SFHFKeychainUtils storeUsername:username
                                 andPassword:[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_password_preference"]
                              forServiceName:@"WordPress.com"
                              updateExisting:YES error:&error];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_password_preference"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        NSString *password = [SFHFKeychainUtils getPasswordForUsername:username
                                                        andServiceName:@"WordPress.com"
                                                                 error:&error];
        if (password != nil) {
            isWPcomAuthenticated = [[WPDataController sharedInstance] authenticateUser:authURL 
                                                                              username:username
                                                                              password:password];
        } else {
            isWPcomAuthenticated = NO;
        }
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

- (void) checkIfStatsShouldRun {
	//check if statsDate exists in user defaults, if not, add it and run stats since this is obviously the first time
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//[defaults setObject:nil forKey:@"statsDate"];  // Uncomment this line to force stats.
	if (![defaults objectForKey:@"statsDate"]){
		NSDate *theDate = [NSDate date];
		[defaults setObject:theDate forKey:@"statsDate"];
		[self performSelectorInBackground:@selector(runStats) withObject:nil];
	}else{
		//if statsDate existed, check if it's 7 days since last stats run, if it is > 7 days, run stats
		NSDate *statsDate = [defaults objectForKey:@"statsDate"];
		NSDate *today = [NSDate date];
		NSTimeInterval difference = [today timeIntervalSinceDate:statsDate];
		NSTimeInterval statsInterval = 7 * 24 * 60 * 60; //number of seconds in 30 days
		if (difference > statsInterval) //if it's been more than 7 days since last stats run
		{
			[self performSelectorInBackground:@selector(runStats) withObject:nil];
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
	int num_blogs = [Blog countWithContext:[self managedObjectContext]];
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

#pragma mark Push Notification delegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	// Send the deviceToken to our server...
	NSString *myToken = [[[[deviceToken description]
					 stringByReplacingOccurrencesOfString: @"<" withString: @""]
					stringByReplacingOccurrencesOfString: @">" withString: @""]
				   stringByReplacingOccurrencesOfString: @" " withString: @""];
	
	// Store the token
	[[NSUserDefaults standardUserDefaults] setObject:myToken forKey:@"apnsDeviceToken"];
	NSLog(@"Registered for push notifications and stored device token: %@", 
		  [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"]);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Failed to register for push notifications: %@", error);
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

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex { 
	switch(buttonIndex) {
		case 0: {
			HelpViewController *helpViewController = [[HelpViewController alloc] init];
			WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
			
			if (DeviceIsPad()) {
				[self.navigationController pushViewController:helpViewController animated:YES];
			}
			else
				[appDelegate.navigationController presentModalViewController:helpViewController animated:YES];
			
			[helpViewController release];
			break;
		}
		case 1:
			//ok
			break;
		default:
			break;
	}
}

@end
