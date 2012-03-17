#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"
#import "Reachability.h"
#import "NSString+Helpers.h"
#import "BlogViewController.h"
#import "BlogSplitViewDetailViewController.h"
#import "CPopoverManager.h"
#import "UIViewController_iPadExtensions.h"
#import "WelcomeViewController.h"
#import "BetaUIWindow.h"
#import "MigrateBlogsFromFiles.h"
#import "InAppSettings.h"
#import "Blog.h"
#import "SFHFKeychainUtils.h"

@interface WordPressAppDelegate (Private)
- (void)setAppBadge;
- (void)checkIfStatsShouldRun;
- (void)runStats;
- (void)showPasswordAlert;
- (void)cleanUnusedMediaFileFromTmpDir;
@end

NSString *CrashFilePath() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"crash_data.txt"];
}

@implementation WordPressAppDelegate

static WordPressAppDelegate *wordPressApp = NULL;

@synthesize window, currentBlog, postID;
@synthesize navigationController, alertRunning, isWPcomAuthenticated;
@synthesize splitViewController, crashReportView, isUploadingPost;
@synthesize connectionAvailable, wpcomAvailable, currentBlogAvailable, wpcomReachability, internetReachability, currentBlogReachability;

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
        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"wp-iphone/%@", appVersion], @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        [dictionary release];

		[self performSelectorInBackground:@selector(checkWPcomAuthentication) withObject:nil];
        
        /* 
         ( The following "init" code loads the Settings.bundle at startup and it is required from InAppSettings. 
         We are not using it since at this point the app already loaded the bundle. Keep the code for future reference. )
         
         //The user defaults from the Settings.bundle are not initialized on startup, and are only initialized when viewed in the Settings App. 
         //InAppSettings has a registerDefaults class method that can be called to initialize all of the user defaults from the Settings.bundle. 
        if([self class] == [WordPressAppDelegate class]){
            [InAppSettings registerDefaults];
        }
         */
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
    [passwordTextField release];
    [wpcomReachability release];
    [internetReachability release];
    [super dealloc];
}

#pragma mark -
#pragma mark UIApplicationDelegate Methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
#ifndef DEBUG
//#warning Need Flurry api key for distribution
#endif
	
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
		[fileManager createDirectoryAtPath:currentDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
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
    
	// Check for pending crash reports
	PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
	if (![crashReporter hasPendingCrashReport]) {
        // Empty log file if we didn't crash last time
        [[FileLogger sharedInstance] reset];
    }
	[FileLogger log:@"Launching WordPress for iOS %@...", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    [FileLogger log:@"device: %@, iOS %@", [[UIDevice currentDevice] platform], [[UIDevice currentDevice] systemVersion]];

    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    // allocate the internet reachability object
    internetReachability = [Reachability reachabilityForInternetConnection];
    
    self.connectionAvailable = [internetReachability isReachable];
    // set the blocks 
    internetReachability.reachableBlock = ^(Reachability*reach)
    {  
        WPLog(@"REACHABLE!");
        self.connectionAvailable = YES;
    };
    internetReachability.unreachableBlock = ^(Reachability*reach)
    {
        WPLog(@"UNREACHABLE!");
        self.connectionAvailable = NO;
    };
    // start the notifier which will cause the reachability object to retain itself!
    [internetReachability startNotifier];
        
    // allocate the WP.com reachability object
    wpcomReachability = [Reachability reachabilityWithHostname:@"wordpress.com"];
    // set the blocks 
    wpcomReachability.reachableBlock = ^(Reachability*reach)
    {  
        WPLog(@"WPCOM REACHABLE!");
        self.wpcomAvailable = YES;
    };
    wpcomReachability.unreachableBlock = ^(Reachability*reach)
    {
        WPLog(@"WPCOM UNREACHABLE!");
        self.wpcomAvailable = NO;
    };
    // start the notifier which will cause the reachability object to retain itself!
    [wpcomReachability startNotifier];
        
    [self setAutoRefreshMarkers];
	
	NSManagedObjectContext *context = [self managedObjectContext];
    if (!context) {
        NSLog(@"\nCould not create *context for self");
    }
	// Stats use core data, so run them after initialization
	[self checkIfStatsShouldRun];

	// Clean media files asynchronously
    // dispatch_async feels a bit faster than performSelectorOnBackground:
    // and we're trying to launch the app as fast as possible
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void) {
        [self cleanUnusedMediaFileFromTmpDir];
    });

	BlogsViewController *blogsViewController = [[BlogsViewController alloc] init];
	crashReportView = [[CrashReportViewController alloc] initWithNibName:@"CrashReportView" bundle:nil];
	
	//BETA FEEDBACK BAR, COMMENT THIS OUT BEFORE RELEASE
	//BetaUIWindow *betaWindow = [[BetaUIWindow alloc] initWithFrame:CGRectZero];
	//betaWindow.hidden = NO;
	//BETA FEEDBACK BAR
	
	if(DeviceIsPad() == NO)
	{
		UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:blogsViewController];
        //aNavigationController.navigationBar.tintColor = [UIColor colorWithRed:31/256.0 green:126/256.0 blue:163/256.0 alpha:1.0];
		self.navigationController = aNavigationController;

		[window addSubview:[navigationController view]];
        window.rootViewController = navigationController;

		if ([Blog countWithContext:context] == 0) {
			WelcomeViewController *wViewController = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:[NSBundle mainBundle]];
			[blogsViewController.navigationController pushViewController:wViewController animated:YES];
			[wViewController release];
		}
		else {
			blogsViewController.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Blogs", @"") style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];
		}
		
	}
	else
	{
		[window addSubview:splitViewController.view];
        window.rootViewController = splitViewController;
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

    // another notification message came from WPWebViewController
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:@"OpenWebPageFailed" object:nil];

    
	NSError *error;
	
	// Check if we previously crashed
	if ([crashReporter hasPendingCrashReport])
		[self handleCrashReport];
    
	// Enable the Crash Reporter
	if (![crashReporter enableCrashReporterAndReturnError: &error])
		NSLog(@"Warning: Could not enable crash reporter: %@", error);
	
	[blogsViewController release];
	[window makeKeyAndVisible];
	
	// Register for push notifications
	[[UIApplication sharedApplication]
	 registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
										 UIRemoteNotificationTypeSound |
										 UIRemoteNotificationTypeAlert)];
    
    //Information related to the reason for its launching, which can include things other than notifications.
    NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif) {
        NSLog(@"Launched with a remote notification as parameter:  %@", remoteNotif);
        [self openNotificationScreenWithOptions:remoteNotif];  
    }
    //the guide say: NO if the application cannot handle the URL resource, otherwise return YES. 
    //The return value is ignored if the application is launched as a result of a remote notification.

#if DEBUG
    /*
     A dictionary containing the credentials for all available protection spaces.
     The dictionary has keys corresponding to the NSURLProtectionSpace objects.
     The values for the NSURLProtectionSpace keys consist of dictionaries where the keys are user name strings, and the value is the corresponding NSURLCredential object.
     */
    [[[NSURLCredentialStorage sharedCredentialStorage] allCredentials] enumerateKeysAndObjectsUsingBlock:^(NSURLProtectionSpace *ps, NSDictionary *dict, BOOL *stop) {
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, NSURLCredential *credential, BOOL *stop) {
            NSLog(@"Removing credential %@ for %@", [credential user], [ps host]);
            [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:ps];
        }];
    }];
#endif
    return YES;
}


-(void) setCurrentBlogReachability:(Reachability *)newBlogReachability {
    WPLog(@"setCurrentBlogReachability");
    [currentBlogReachability stopNotifier];
    [currentBlogReachability release];
    self.currentBlogAvailable = NO;
    currentBlogReachability = [newBlogReachability retain];
    
    // set the blocks 
    currentBlogReachability.reachableBlock = ^(Reachability*reach)
    {  
        WPLog(@"Current Blog REACHABLE!");
        self.currentBlogAvailable = YES;
    };
    currentBlogReachability.unreachableBlock = ^(Reachability*reach)
    {
        WPLog(@"Current Blog UNREACHABLE!");
        self.currentBlogAvailable = NO;
    };
    // start the notifier which will cause the reachability object to retain itself!
    [currentBlogReachability startNotifier];
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if (url && [url isKindOfClass:[NSURL class]]) {
        NSString *URLString = [url absoluteString];
        NSLog(@"Application launched with URL: %@", URLString);
        if ([[url host] isEqualToString:@"oauth"]) {
            NSDictionary *params = [[url query] dictionaryFromQueryString];
            oauthCallback = [[params objectForKey:@"callback"] retain];
            NSString *clientId = [params objectForKey:@"client_id"];
            NSString *redirectUrl = [params objectForKey:@"redirect_uri"];
            NSString *secret = [params objectForKey:@"secret"];
            if (clientId && redirectUrl && secret && oauthCallback) {
                [WPComOAuthController presentWithClientId:clientId redirectUrl:redirectUrl clientSecret:secret delegate:self];
            }
        }
        
        return YES;
    } else {
        return NO;
    }
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
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [self setAppBadge];
	
	if (DeviceIsPad()) {
		UIViewController *topVC = self.masterNavigationController.topViewController;
        
		if (topVC && [topVC isKindOfClass:[BlogViewController class]]) {
			[(BlogViewController *)topVC saveState];
		}
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
    //Keep the app alive in the background if we are uploading a post, currently only used for quick photo posts
    UIApplication *app = [UIApplication sharedApplication];
    if (!isUploadingPost && [app respondsToSelector:@selector(endBackgroundTask:)]) {
        if (bgTask != UIBackgroundTaskInvalid) {
            [app endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }
    }
    
    if ([app respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            // Synchronize the cleanup call on the main thread in case
            // the task actually finishes at around the same time.
            dispatch_async(dispatch_get_main_queue(), ^{
                if (bgTask != UIBackgroundTaskInvalid)
                {
                    [app endBackgroundTask:bgTask];
                    bgTask = UIBackgroundTaskInvalid;
                }
            });
        }];
    }

    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        WPFLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    NSDate *lastReaderCache = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastReaderCache"];
    if (lastReaderCache == nil || [lastReaderCache timeIntervalSinceNow] < -3600) { // Update reader cache every hour
        [FileLogger log:@"Last reader cached at %@, refreshing cache", lastReaderCache];
        [self performSelectorInBackground:@selector(checkWPcomAuthentication) withObject:nil];
    } else {
        [FileLogger log:@"Last reader cached at %@, not refreshing cache", lastReaderCache];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];    
  
    if (passwordAlertRunning && passwordTextField != nil)
        [passwordTextField resignFirstResponder];
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DismissAlertViewKeyboard" object:nil];
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationDidBecomeActive" object:nil];
    
}


- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)oldStatusBarFrame {
	//The guide says: After calling this method, the application also posts a UIApplicationDidChangeStatusBarFrameNotification notification to give interested objects a chance to respond to the change.
	//but seems that the notification is never sent.
	//we are using a custom notification
	[[NSNotificationCenter defaultCenter] postNotificationName:DidChangeStatusBarFrame object:nil];
}


#pragma mark -
#pragma mark Public Methods

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
	WPLog(@"Showing alert with title: %@", message);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                          message:message
                          delegate:self
						cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
						otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    [alert show];
    [alert release];
}

- (void)showNotificationErrorAlert:(NSNotification *)notification {
	NSString *cleanedErrorMsg = nil;
	
	if([self isAlertRunning] == YES) return; //another alert is already shown 
	[self setAlertRunning:YES];
	
	if([[notification object] isKindOfClass:[NSError class]]) {
		
		NSError *err  = (NSError *)[notification object];
		cleanedErrorMsg = [err localizedDescription];
		
		//org.wordpress.iphone --> XML-RPC errors
		if ([[err domain] isEqualToString:@"org.wordpress.iphone"]){
			if([err code] == 401)
				cleanedErrorMsg = NSLocalizedString(@"Sorry, you cannot access this feature. Please check your User Role on this blog.", @"");
			else if([err code] == 403) { //403 = bad username/password
				NSDictionary *errInfo = [notification userInfo];
				//check if the user has NOT changed the blog during the loading
				if( (errInfo != nil) && ([errInfo objectForKey:@"currentBlog"] != nil ) 
				   && currentBlog == [errInfo objectForKey:@"currentBlog"] ) {
                    passwordAlertRunning = YES;
					[self performSelectorOnMainThread:@selector(showPasswordAlert) withObject:nil waitUntilDone:NO];
				} else {
					//do not show the alert
					[self setAlertRunning:NO];
				}
				return;
			}
		}
        
        // ignore HTTP auth canceled errors
        if ([err.domain isEqual:NSURLErrorDomain] && err.code == NSURLErrorUserCancelledAuthentication) {
            [self setAlertRunning:NO];
            return;
        }
	} else { //the notification obj is a String
		cleanedErrorMsg  = (NSString *)[notification object];
	}
	
	if([cleanedErrorMsg rangeOfString:@"NSXMLParserErrorDomain"].location != NSNotFound )
		cleanedErrorMsg = NSLocalizedString(@"The app can't recognize the server response. Please, check the configuration of your blog.", @"");
	
	[self showAlertWithTitle:NSLocalizedString(@"Error", @"") message:cleanedErrorMsg];
}


- (void)showPasswordAlert {

	UILabel *labelPasswd;
	
	NSString *lineBreaks;
	
	if (DeviceIsPad())
		lineBreaks = @"\n\n\n\n";
	else 
		lineBreaks = @"\n\n\n";
	
	UIAlertView *customSizeAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Incorrect Password", @"") 
															  message:lineBreaks // IMPORTANT
															 delegate:self 
													cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
													otherButtonTitles:NSLocalizedString(@"Save", @""), nil];
	
	customSizeAlert.tag = 101;
	
	labelPasswd = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 48.0, 260.0, 29.0)];
	labelPasswd.backgroundColor = [UIColor clearColor];
	labelPasswd.textColor = [UIColor whiteColor];
	labelPasswd.text = NSLocalizedString(@"Please update your password:", @"");
	[customSizeAlert addSubview:labelPasswd];
	[labelPasswd release];
	
	passwordTextField = [[UITextField alloc]  initWithFrame:CGRectMake(12.0, 82.0, 260.0, 29.0)]; 
	[passwordTextField setBackgroundColor:[UIColor whiteColor]];
	[passwordTextField setContentVerticalAlignment: UIControlContentVerticalAlignmentCenter];
	passwordTextField.keyboardType = UIKeyboardTypeDefault;
	passwordTextField.secureTextEntry = YES;
	
	[passwordTextField setTag:123];
	
	[customSizeAlert addSubview:passwordTextField];
	
	//fix the dialog position for older devices on iOS 3
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	if (version <= 3.1)
	{
		customSizeAlert.transform = CGAffineTransformTranslate(customSizeAlert.transform, 0.0, 100.0);
	}
	
	[customSizeAlert show];
	[customSizeAlert release];
	
	[passwordTextField becomeFirstResponder]; //this line should always be called on MainThread
    [passwordTextField release];
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
            fabric.contentMode = UIViewContentModeCenter;
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
			WPFLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
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
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error establishing database connection.", @"") 
														 message:NSLocalizedString(@"Please delete the app and reinstall.", @"") 
														delegate:nil 
											   cancelButtonTitle:NSLocalizedString(@"OK", @"") 
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

- (NSString *)readerCachePath {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [cachePath stringByAppendingPathComponent:@"reader.html"];
}

- (NSString *)applicationUserAgent {
  return [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
}

#pragma mark -
#pragma mark Private Methods

- (void)setAppBadge {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)checkWPcomAuthentication {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *authURL = @"https://wordpress.com/wp-login.php";
	
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
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:authURL]];
            [request setHTTPMethod:@"POST"];
            [request setValue:username forHTTPHeaderField:@"log"];
            [request setValue:password forHTTPHeaderField:@"pwd"];
            NSString *redirect_to = [WPWebAppViewController authorizeHybridURL:[NSURL URLWithString:kMobileReaderURL]].absoluteString;
            [request setValue:redirect_to forHTTPHeaderField:@"redirect_to"];
            [request addValue:[self applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                WPFLog(@"Authenticated in WP.com, cached reader");
                NSData *readerData = responseObject;
                [readerData writeToFile:[self readerCachePath] atomically:YES];
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastReaderCache"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReaderCached" object:nil];
                isWPcomAuthenticated = YES;
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                WPFLog(@"Error logging into wp.com: %@", [error localizedDescription]);
                isWPcomAuthenticated = NO;
            }];
            
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [queue addOperation:operation];
            
            [request release];
            [operation release];
            [queue release];
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



- (void) checkIfStatsShouldRun {
    if (NO) { // Switch this to YES to debug stats/update check
        [self runStats];
        return;
    }
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
            // WARNING: for some reason, if runStats is called in a background thread
            // NSURLConnection doesn't launch and stats are not sent
            // Don't change this or be really sure it's working
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
	
	NSString *deviceModel = [[[UIDevice currentDevice] platform] stringByUrlEncoding];
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

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *theDate = [NSDate date];
	[defaults setObject:theDate forKey:@"statsDate"];
	[defaults synchronize];
}

- (void)cleanUnusedMediaFileFromTmpDir {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSMutableArray *mediaToKeep = [NSMutableArray array];

    NSError *error = nil;
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
    [context setUndoManager:nil];
    [context setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Media" inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY posts.blog != NULL"];
    [fetchRequest setPredicate:predicate];
    NSArray *mediaObjectsToKeep = [context executeFetchRequest:fetchRequest error:&error];
    if (error != nil) {
        WPFLog(@"Error cleaning up tmp files: %@", [error localizedDescription]);
    }
	//get a references to media files linked in a post
    NSLog(@"%i media items to check for cleanup", [mediaObjectsToKeep count]);
	for (Media *media in mediaObjectsToKeep) {
        [mediaToKeep addObject:media.localURL];
	}

	//searches for jpg files within the app temp file
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSArray *contentsOfDir = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];

	for (NSString *currentPath in contentsOfDir)
		if([currentPath isMatchedByRegex:@".jpg$"]) {
			NSString *filepath = [documentsDirectory stringByAppendingPathComponent:currentPath];

			BOOL keep = NO;
			//if the file is not referenced in any post we can delete it
			for (NSString *currentMediaToKeepPath in mediaToKeep) {
				if([currentMediaToKeepPath isEqualToString:filepath]) {
					keep = YES;
					break;
				}
			}

			if(keep == NO) {
				[fileManager removeItemAtPath:filepath error:NULL];
			}
		}

	[pool release];
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

    [self sendApnsToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"Failed to register for push notifications: %@", error);
}

// The notification is delivered when the application is running
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveRemoteNotification: %@", userInfo);
    application.applicationIconBadgeNumber = 0;
    /*
     {
     aps =     {
     alert = "New comment on test from maria";
     badge = 1;
     sound = default;
     };
     "blog_id" = 16841252;
     "comment_id" = 571;
     }*/
    
    //You can determine whether an application is launched as a result of the user tapping the action button or 
    //whether the notification was delivered to the already-running application by examining the application state.
    switch (application.applicationState) {
        case UIApplicationStateActive:
            NSLog(@"app state UIApplicationStateActive"); //application is in foreground
            //we should show an alert since the OS doesn't show anything in this case. Unfortunately no sound!!
            if([self isAlertRunning] != YES) {
                [self setAlertRunning:YES];
                NSString *msg = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
                [lastNotificationInfo release];
                lastNotificationInfo = [userInfo retain];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New comment", @"")
                                                                message:msg
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                                      otherButtonTitles:NSLocalizedString(@"View", @"View comment from push notification"), nil];
                alert.tag = kNotificationNewComment;
                [alert show];
                [alert release];
            }
            break;
        case UIApplicationStateInactive:
            NSLog(@"app state UIApplicationStateInactive"); //application is in bg and the user tapped the view button
             [self openNotificationScreenWithOptions:userInfo];
            break;
        case UIApplicationStateBackground:
            NSLog(@" app state UIApplicationStateBackground"); //?? doh!
            break;
        default:
            break;
    }
}

- (void)sendApnsToken {	
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"];
    if( nil == token ) return; //no apns token available
    
    NSString *authURL = kNotificationAuthURL;   	
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
            AFXMLRPCClient *api = [[AFXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
            [api callMethod:@"wpcom.mobile_push_register_token"
                 parameters:[NSArray arrayWithObjects:username, password, token, [[UIDevice currentDevice] uniqueIdentifier], nil]
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        [self sendPushNotificationBlogsList];
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        WPFLog(@"Couldn't register token: %@", [error localizedDescription]);
                    }];
        } 
	}
}

- (void)sendPushNotificationBlogsList {    
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"];
    if( nil == token ) return; //no apns token available
    
    NSString *authURL = kNotificationAuthURL;   	
    NSError *error = nil;
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"] == nil) return;
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
    if (password == nil) return;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:self.managedObjectContext]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"blogName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    NSArray *blogs = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
    NSMutableArray *blogsID = [NSMutableArray array];
    
    //get a references to media files linked in a post
    for (Blog *blog in blogs) {
        if( [blog isWPcom] ) {
            [blogsID addObject:[blog blogID] ];
        }
    }
    
    AFXMLRPCClient *api = [[AFXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
    [api callMethod:@"wpcom.mobile_push_set_blogs_list"
         parameters:[NSArray arrayWithObjects:username, password, token, blogsID, nil]
            success:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                WPFLog(@"Failed registering blogs list: %@", [error localizedDescription]);
            }];
    
    [fetchRequest release];
    [sortDescriptor release]; sortDescriptor = nil;
    [sortDescriptors release]; sortDescriptors = nil;
}

- (void)openNotificationScreenWithOptions:(NSDictionary *)remoteNotif {
    NSLog(@"Opening the notification screen");
    Blog *blog = [Blog findWithId:[[remoteNotif objectForKey:@"blog_id"] intValue] withContext:self.managedObjectContext];
    if (blog) {
        [blog syncCommentsWithSuccess:nil failure:nil];

        UIViewController *rootViewController = self.window.rootViewController;
        if ([rootViewController isKindOfClass:[UISplitViewController class]]) {
            rootViewController = [((UISplitViewController *)rootViewController).viewControllers objectAtIndex:0];
        }
        UINavigationController *nav = (UINavigationController *)rootViewController;
        [nav popToRootViewControllerAnimated:NO];
        BlogsViewController *blogsViewController = (BlogsViewController *)nav.topViewController;
        [blogsViewController showBlog:blog animated:NO];
        BlogViewController *blogViewController = (BlogViewController *)nav.visibleViewController;
        blogViewController.selectedIndex = 2;
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
							   cancelButtonTitle:NSLocalizedString(@"OK", @"")
							   otherButtonTitles:nil];
	[errorAlert show];
	[errorAlert release];
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection {
	NSString *statsDataString = [[[NSString alloc] initWithData:statsData encoding:NSUTF8StringEncoding] autorelease];
    statsDataString = [[statsDataString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:0];
	NSString *appversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    if ([statsDataString compare:appversion] > 0) {
        NSLog(@"There's a new version: %@", statsDataString);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Update Available", @"")
                                                        message:NSLocalizedString(@"A new version of WordPress for iOS is now available", @"")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                              otherButtonTitles:NSLocalizedString(@"Update Now", @""), nil];
        alert.tag = 102;
        [alert show];
    }
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
	[barButtonItem setTitle:NSLocalizedString(@"My Blog", @"")];
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

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
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
	[self setAlertRunning:NO];
	
	if (alertView.tag == 101) { //Password Alert
        passwordAlertRunning = NO;
		if(currentBlog != nil) {
			NSError *error = nil;
			
			if ([passwordTextField.text isEqualToString:@""]) 
				return;
			
			//check if the current blog is a WP.COM blog
			if(currentBlog.isWPcom) {
				[SFHFKeychainUtils storeUsername:currentBlog.username
									 andPassword:passwordTextField.text
								  forServiceName:@"WordPress.com"
								  updateExisting:YES
										   error:&error];
			} else {
				[SFHFKeychainUtils storeUsername:currentBlog.username
									 andPassword:passwordTextField.text
								  forServiceName:currentBlog.hostURL
								  updateExisting:YES
										   error:&error];
			}
			
			if (error) {
				[FileLogger log:@"%@ %@ Error saving password for %@: %@", self, NSStringFromSelector(_cmd), currentBlog.url, error];
			} else {
				[FileLogger log:@"%@ %@ %@", self, NSStringFromSelector(_cmd), currentBlog.url];
			}
		}
    } else if (alertView.tag == 102) { // Update alert
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/wordpress/id335703880?mt=8&ls=1"]];
        }
    } else if (alertView.tag == kNotificationNewComment) {
        if (buttonIndex == 1) {
            [self openNotificationScreenWithOptions:lastNotificationInfo];
            [lastNotificationInfo release]; lastNotificationInfo = nil;
        }
	} else { 
		//Need Help Alert
		switch(buttonIndex) {
			case 0: {
				HelpViewController *helpViewController = [[HelpViewController alloc] init];
				WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
				
				if (DeviceIsPad() && self.splitViewController.modalViewController) {
					[self.navigationController pushViewController:helpViewController animated:YES];
				}
				else {
					if (DeviceIsPad()) {
						helpViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
						helpViewController.modalPresentationStyle = UIModalPresentationFormSheet;
						[splitViewController presentModalViewController:helpViewController animated:YES];
					}
					else
						[appDelegate.navigationController presentModalViewController:helpViewController animated:YES];
				}
				
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
}

#pragma mark - WPComOAuthDelegate

- (void)controllerDidCancel:(WPComOAuthController *)controller {
    NSLog(@"OAuth canceled");
    NSURL *callback = [NSURL URLWithString:[NSString stringWithFormat:@"%@://wordpress-sso", oauthCallback]];
    [[UIApplication sharedApplication] openURL:callback];
}
- (void)controller:(WPComOAuthController *)controller didAuthenticateWithToken:(NSString *)token blog:(NSString *)blogUrl {
    NSLog(@"OAuth successful. Token %@ Blog %@", token, blogUrl);
    NSString *encodedToken = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (CFStringRef)token,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8 );
    NSURL *callback = [NSURL URLWithString:[NSString stringWithFormat:@"%@://wordpress-sso?token=%@&blog=%@",
                                            oauthCallback,
                                            encodedToken,
                                            [blogUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    NSLog(@"Launching %@", callback);
    [[UIApplication sharedApplication] openURL:callback];
}

@end
