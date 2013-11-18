#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import <WordPressApi/WordPressApi.h>
#import <Crashlytics/Crashlytics.h>
#import <GooglePlus/GooglePlus.h>

#import "WordPressAppDelegate.h"
#import "Reachability.h"
#import "NSString+Helpers.h"
#import "CPopoverManager.h"
#import "BetaUIWindow.h"
#import "MigrateBlogsFromFiles.h"
#import "Blog.h"
#import "Media.h"
#import "CameraPlusPickerManager.h"
#import "UIDevice+WordPressIdentifier.h"
#import "WordPressComApi.h"
#import "PostsViewController.h"
#import "CommentsViewController.h"
#import "StatsWebViewController.h"
#import "WordPressComApiCredentials.h"
#import "PocketAPI.h"
#import "WPMobileStats.h"
#import "WPComLanguages.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "WPAccount.h"
#import "Note.h"
#import "UIColor+Helpers.h"
#import <Security/Security.h>
#import "SupportViewController.h"
#import "ContextManager.h"
#import "ReaderPostsViewController.h"
#import "NotificationsViewController.h"
#import "BlogListViewController.h"
#import "GeneralWalkthroughViewController.h"

@interface WordPressAppDelegate (Private) <CrashlyticsDelegate>

@end

int ddLogLevel = LOG_LEVEL_INFO;

@implementation WordPressAppDelegate {
    BOOL _listeningForBlogChanges;

    // We have this so we can make sure not to send two Application Opened related events. This comes
    // into play when we receive a push notification and the user opens the app in response to that. We
    // don't want to double count the events in Mixpanel so we use this to ensure it doesn't happen.
    BOOL _hasRecordedApplicationOpenedEvent;
}

@synthesize window, currentBlog, postID;
@synthesize navigationController, alertRunning, isWPcomAuthenticated;
@synthesize isUploadingPost;
@synthesize connectionAvailable, wpcomAvailable, currentBlogAvailable, wpcomReachability, internetReachability, currentBlogReachability;

#pragma mark -
#pragma mark Class Methods

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate {
    return (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
}

+ (void)wipeAllKeychainItems
{
    NSArray *secItemClasses = @[(__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecClassInternetPassword,
                                (__bridge id)kSecClassCertificate,
                                (__bridge id)kSecClassKey,
                                (__bridge id)kSecClassIdentity];
    for (id secItemClass in secItemClasses) {
        NSDictionary *spec = @{(__bridge id)kSecClass : secItemClass};
        SecItemDelete((__bridge CFDictionaryRef)spec);
    }
}

+ (void)fixKeychainAccess
{
	NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlocked,
                            (__bridge id)kSecReturnAttributes: @YES,
                            (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll
                            };

    CFTypeRef result = NULL;
	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess) {
        return;
    }
    DDLogVerbose(@"Fixing keychain items with wrong access requirements");
    for (NSDictionary *item in (__bridge_transfer NSArray *)result) {
        NSDictionary *itemQuery = @{
                                    (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                    (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlocked,
                                    (__bridge id)kSecAttrService: item[(__bridge id)kSecAttrService],
                                    (__bridge id)kSecAttrAccount: item[(__bridge id)kSecAttrAccount],
                                    (__bridge id)kSecReturnAttributes: @YES,
                                    (__bridge id)kSecReturnData: @YES,
                                    };

        CFTypeRef itemResult = NULL;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)itemQuery, &itemResult);
        if (status == errSecSuccess) {
            NSDictionary *itemDictionary = (__bridge NSDictionary *)itemResult;
            NSDictionary *updateQuery = @{
                                        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlocked,
                                        (__bridge id)kSecAttrService: item[(__bridge id)kSecAttrService],
                                        (__bridge id)kSecAttrAccount: item[(__bridge id)kSecAttrAccount],
                                        };
            NSDictionary *updatedAttributes = @{
                                                (__bridge id)kSecValueData: itemDictionary[(__bridge id)kSecValueData],
                                                (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
                                                };
            status = SecItemUpdate((__bridge CFDictionaryRef)updateQuery, (__bridge CFDictionaryRef)updatedAttributes);
            if (status == errSecSuccess) {
                DDLogInfo(@"Migrated keychain item %@", item);
            } else {
                DDLogError(@"Error migrating keychain item: %d", status);
            }
        } else {
            DDLogError(@"Error migrating keychain item: %d", status);
        }
    }
    NSLog(@"end fixing");
}

#pragma mark -
#pragma mark UIApplicationDelegate Methods

- (void)setupUserAgent {
    // Keep a copy of the original userAgent for use with certain webviews in the app.
    UIWebView *webView = [[UIWebView alloc] init];
    NSString *defaultUA = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"version_preference"];
    NSString *appUA = [NSString stringWithFormat:@"wp-iphone/%@ (%@ %@, %@) Mobile",
                           appVersion,
                           [[UIDevice currentDevice] systemName],
                           [[UIDevice currentDevice] systemVersion],
                           [[UIDevice currentDevice] model]
                           ];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys: appUA, @"UserAgent", defaultUA, @"DefaultUserAgent", appUA, @"AppUserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}

- (void)setupReachability {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    // Set the wpcom availability to YES to avoid issues with lazy reachibility notifier
    self.wpcomAvailable = YES;
    // Same for general internet connection
    self.connectionAvailable = YES;

    // allocate the internet reachability object
    internetReachability = [Reachability reachabilityForInternetConnection];
    
    self.connectionAvailable = [internetReachability isReachable];
    // set the blocks 
    internetReachability.reachableBlock = ^(Reachability*reach)
    {  
        DDLogInfo(@"Internet connection is back");
        self.connectionAvailable = YES;
    };
    internetReachability.unreachableBlock = ^(Reachability*reach)
    {
        DDLogInfo(@"No internet connection");
        self.connectionAvailable = NO;
    };
    // start the notifier which will cause the reachability object to retain itself!
    [internetReachability startNotifier];
    
    // allocate the WP.com reachability object
    wpcomReachability = [Reachability reachabilityWithHostname:@"wordpress.com"];
    // set the blocks 
    wpcomReachability.reachableBlock = ^(Reachability*reach)
    {  
        DDLogInfo(@"Connection to WordPress.com is back");
        self.wpcomAvailable = YES;
    };
    wpcomReachability.unreachableBlock = ^(Reachability*reach)
    {
        DDLogInfo(@"No connection to WordPress.com");
        self.wpcomAvailable = NO;
    };
    // start the notifier which will cause the reachability object to retain itself!
    [wpcomReachability startNotifier];
#pragma clang diagnostic pop
}

- (void)setupPocket {
    [[PocketAPI sharedAPI] setConsumerKey:[WordPressComApiCredentials pocketConsumerKey]];
}

- (void)setupSingleSignOn {
    if ([[WPAccount defaultWordPressComAccount] username]) {
        [[WPComOAuthController sharedController] setWordPressComUsername:[[WPAccount defaultWordPressComAccount] username]];
        [[WPComOAuthController sharedController] setWordPressComPassword:[[WPAccount defaultWordPressComAccount] password]];
    }
}

- (void)configureCrashlytics {
#if DEBUG
    return;
#endif

    if ([[WordPressComApiCredentials crashlyticsApiKey] length] == 0) {
        return;
    }
    
    [Crashlytics startWithAPIKey:[WordPressComApiCredentials crashlyticsApiKey]];
    [[Crashlytics sharedInstance] setDelegate:self];

    BOOL hasCredentials = [[WordPressComApi sharedApi] hasCredentials];
    [self setCommonCrashlyticsParameters];

    if (hasCredentials && [[WPAccount defaultWordPressComAccount] username] != nil) {
        [Crashlytics setUserName:[[WPAccount defaultWordPressComAccount] username]];
    }

    void (^wpcomLoggedInBlock)(NSNotification *) = ^(NSNotification *note) {
        [Crashlytics setUserName:[[WPAccount defaultWordPressComAccount] username]];
        [self setCommonCrashlyticsParameters];
    };
    void (^wpcomLoggedOutBlock)(NSNotification *) = ^(NSNotification *note) {
        [Crashlytics setUserName:nil];
        [self setCommonCrashlyticsParameters];
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLoginNotification object:nil queue:nil usingBlock:wpcomLoggedInBlock];
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLogoutNotification object:nil queue:nil usingBlock:wpcomLoggedOutBlock];
}

- (void)setCommonCrashlyticsParameters
{
    [Crashlytics setObjectValue:[NSNumber numberWithBool:[[WordPressComApi sharedApi] hasCredentials]] forKey:@"logged_in"];
    [Crashlytics setObjectValue:@([[WordPressComApi sharedApi] hasCredentials]) forKey:@"connected_to_dotcom"];
    [Crashlytics setObjectValue:@([Blog countWithContext:[[ContextManager sharedInstance] mainContext]]) forKey:@"number_of_blogs"];
}

- (BOOL)noBlogsAndNoWordPressDotComAccount {
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    NSManagedObjectContext *moc = [[ContextManager sharedInstance] mainContext];
    NSUInteger blogs = [moc countForFetchRequest:fetchRequest error:&error];
    return blogs == 0 && ![WPAccount defaultWordPressComAccount];
}

- (void)showWelcomeScreenIfNeeded {
    if ([self noBlogsAndNoWordPressDotComAccount]) {
        [WordPressAppDelegate wipeAllKeychainItems];
        
        GeneralWalkthroughViewController *welcomeViewController = [[GeneralWalkthroughViewController alloc] init];
        
        UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];
        aNavigationController.navigationBar.translucent = NO;
        aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [window.rootViewController presentViewController:aNavigationController animated:NO completion:nil];
    }
}

- (UITabBarController *)createTabBarController {
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    if ([tabBarController.tabBar respondsToSelector:@selector(setTranslucent:)]) {
        [tabBarController.tabBar setTranslucent:NO];
    }
    
    self.readerPostsViewController = [[ReaderPostsViewController alloc] init];
    UINavigationController *readerNavigationController = [[UINavigationController alloc] initWithRootViewController:self.readerPostsViewController];
    readerNavigationController.navigationBar.translucent = NO;
    readerNavigationController.tabBarItem.image = [UIImage imageNamed:@"icon-tab-reader"];
    self.readerPostsViewController.title = @"Reader";
    
    self.notificationsViewController = [[NotificationsViewController alloc] init];
    UINavigationController *notificationsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.notificationsViewController];
    notificationsNavigationController.navigationBar.translucent = NO;
    notificationsNavigationController.tabBarItem.image = [UIImage imageNamed:@"icon-tab-notifications"];
    self.notificationsViewController.title = @"Notifications";
    
    BlogListViewController *blogListViewController = [[BlogListViewController alloc] init];
    UINavigationController *blogListNavigationController = [[UINavigationController alloc] initWithRootViewController:blogListViewController];
    blogListNavigationController.navigationBar.translucent = NO;
    blogListNavigationController.tabBarItem.image = [UIImage imageNamed:@"icon-tab-blogs"];
    blogListViewController.title = @"My Blogs";
    tabBarController.viewControllers = [NSArray arrayWithObjects:blogListNavigationController, readerNavigationController, notificationsNavigationController, nil];
    
    [tabBarController setSelectedViewController:readerNavigationController];

    return tabBarController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIDevice *device = [UIDevice currentDevice];
    NSInteger crashCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"crashCount"];

    [self configureLogging];
    [self configureCrashlytics];

    NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    NSString *currentLanguage = [languages objectAtIndex:0];
    BOOL extraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"];
    
    DDLogInfo(@"===========================================================================");
	DDLogInfo(@"Launching WordPress for iOS %@...", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
    DDLogInfo(@"Crash count:       %d", crashCount);
#ifdef DEBUG
    DDLogInfo(@"Debug mode:  Debug");
#else
    DDLogInfo(@"Debug mode:  Production");
#endif
    DDLogInfo(@"Extra debug: %@", extraDebug ? @"YES" : @"NO");
    DDLogInfo(@"Device model: %@ (%@)", [UIDeviceHardware platformString], [UIDeviceHardware platform]);
    DDLogInfo(@"OS:        %@ %@", [device systemName], [device systemVersion]);
    DDLogInfo(@"Language:  %@", currentLanguage);
    DDLogInfo(@"UDID:      %@", [device wordpressIdentifier]);
    DDLogInfo(@"APN token: %@", [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey]);
    DDLogInfo(@"===========================================================================");

    [self setupUserAgent];
    [WPMobileStats initializeStats];
    [[GPPSignIn sharedInstance] setClientID:[WordPressComApiCredentials googlePlusClientId]];

    if([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_authenticated_flag"] != nil) {
        NSString *tempIsAuthenticated = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_authenticated_flag"];
        if([tempIsAuthenticated isEqualToString:@"1"])
            self.isWPcomAuthenticated = YES;
    }

	// Set current directory for WordPress app
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *currentDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"wordpress"];

	BOOL isDir;

	if (![fileManager fileExistsAtPath:currentDirectoryPath isDirectory:&isDir] || !isDir) {
		[fileManager createDirectoryAtPath:currentDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	// set the current dir
	[fileManager changeCurrentDirectoryPath:currentDirectoryPath];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [self setupReachability];
	
	[self toggleExtraDebuggingIfNeeded];

	// Stats use core data, so run them after initialization
	[self checkIfStatsShouldRun];
    
    [self checkIfFeedbackShouldBeEnabled];

	// Clean media files asynchronously
    // dispatch_async feels a bit faster than performSelectorOnBackground:
    // and we're trying to launch the app as fast as possible
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        [self cleanUnusedMediaFileFromTmpDir];
    });

    [self checkWPcomAuthentication];

    [self customizeAppearance];
    
    [self setupPocket];
    [self setupSingleSignOn];

    CGRect bounds = [[UIScreen mainScreen] bounds];
    [window setFrame:bounds];
    [window setBounds:bounds]; // for good measure.
    
    window.backgroundColor = [UIColor blackColor];
    window.rootViewController = [self createTabBarController];
    [self showWelcomeScreenIfNeeded];

	//listener for XML-RPC errors
	//in the future we could put the errors message in a dedicated screen that users can bring to front when samething went wrong, and can take a look at the error msg.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:kXML_RPC_ERROR_OCCURS object:nil];
	
	// another notification message came from comments --> CommentUploadFailed
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:@"CommentUploadFailed" object:nil];

    // another notification message came from WPWebViewController
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:@"OpenWebPageFailed" object:nil];


	[window makeKeyAndVisible];
    

	[self registerForPushNotifications];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [WordPressAppDelegate fixKeychainAccess];
    });
    
    //Information related to the reason for its launching, which can include things other than notifications.
    NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];

    if (remoteNotif) {
        _hasRecordedApplicationOpenedEvent = YES;
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAppOpenedDueToPushNotification];

        DDLogInfo(@"Launched with a remote notification as parameter:  %@", remoteNotif);
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
            DDLogVerbose(@"Removing credential %@ for %@", [credential user], [ps host]);
            [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:ps];
        }];
    }];
#endif
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[GPPShare sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation]) {
        return YES;
    }

    if ([[PocketAPI sharedAPI] handleOpenURL:url]) {
        return YES;
    }

    if ([[CameraPlusPickerManager sharedManager] shouldHandleURLAsCameraPlusPickerCallback:url]) {
        /* Note that your application has been in the background and may have been terminated.
         * The only CameraPlusPickerManager state that is restored is the pickerMode, which is
         * restored to indicate the mode used to pick images.
         */

        /* Handle the callback and notify the delegate. */
        [[CameraPlusPickerManager sharedManager] handleCameraPlusPickerCallback:url usingBlock:^(CameraPlusPickedImages *images) {
            DDLogInfo(@"Camera+ returned %@", [images images]);
            UIImage *image = [images image];
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:image forKey:@"image"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kCameraPlusImagesNotification object:nil userInfo:userInfo];
        } cancelBlock:^(void) {
            DDLogInfo(@"Camera+ picker canceled");
        }];
        return YES;
    }

    if ([WordPressApi handleOpenURL:url]) {
        return YES;
    }

    if (url && [url isKindOfClass:[NSURL class]]) {
        NSString *URLString = [url absoluteString];
        DDLogInfo(@"Application launched with URL: %@", URLString);
        if ([[url absoluteString] hasPrefix:@"wordpress://wpcom_signup_completed"]) {
            NSDictionary *params = [[url query] dictionaryFromQueryString];
            DDLogInfo(@"%@", params);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"wpcomSignupNotification" object:nil userInfo:params];
            return YES;
        }
    }

    return NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    [self setAppBadge];
    [WPMobileStats endSession];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

    [WPMobileStats trackEventForWPComWithSavedProperties:StatsEventAppClosed];
    [self resetStatRelatedVariables];
    [WPMobileStats pauseSession];
    
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [WPMobileStats resumeSession];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));    
  
    if (passwordAlertRunning && passwordTextField != nil) {
        [passwordTextField resignFirstResponder];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DismissAlertViewKeyboard" object:nil];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationDidBecomeActive" object:nil];
    
    if (!_hasRecordedApplicationOpenedEvent) {
        [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAppOpened];
    }
    
    // Clear notifications badge and update server
    [self setAppBadge];
    [[WordPressComApi sharedApi] syncPushNotificationInfo];
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
	DDLogInfo(@"Showing alert with title: %@", message);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                          message:message
                          delegate:self
						cancelButtonTitle:NSLocalizedString(@"Need Help?", @"'Need help?' button label, links off to the WP for iOS FAQ.")
						otherButtonTitles:NSLocalizedString(@"OK", @"OK button label."), nil];
    [alert show];
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
	
	[self showAlertWithTitle:NSLocalizedString(@"Error", @"Generic popup title for any type of error.") message:cleanedErrorMsg];
}

- (void)useDefaultUserAgent {
    NSString *ua = [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultUserAgent"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:ua, @"UserAgent", nil];
    // We have to call registerDefaults else the change isn't picked up by UIWebViews.
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    DDLogVerbose(@"User-Agent set to: %@", ua);
}

- (void)useAppUserAgent {
    NSString *ua = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppUserAgent"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:ua, @"UserAgent", nil];
    // We have to call registerDefaults else the change isn't picked up by UIWebViews.
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    
    DDLogVerbose(@"User-Agent set to: %@", ua);
}

- (NSString *)applicationUserAgent {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
}

#pragma mark -
#pragma mark Private Methods

- (void)configureLogging
{
    // Remove the old Documents/wordpress.log if it exists
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"wordpress.log"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
    
    // Sets up the CocoaLumberjack logging; debug output to console and file
#ifdef DEBUG
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif
    
    self.fileLogger = [[DDFileLogger alloc] init];
    self.fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    self.fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:self.fileLogger];
    
    BOOL extraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"];
    if (extraDebug) {
        ddLogLevel = LOG_LEVEL_VERBOSE;
    }
}

- (void)customizeAppearance {
    if (IS_IOS7) {
        [self customizeForiOS7];
    } else {
        [self customizeForiOS6];
    }
}

- (void)customizeForiOS6
{
    // If UIAppearance is supported, configure global styles.
    //Configure navigation bar style if >= iOS 5
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        [[UIToolbar appearance] setTintColor:[WPStyleGuide littleEddieGrey]];
        
        [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_bg"] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0],
          UITextAttributeTextColor,
          [UIColor whiteColor],
          UITextAttributeTextShadowColor,
          [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
          UITextAttributeTextShadowOffset,
          nil]];
        
        //        [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithRed:229.0/255.0 green:229.0/255.0 blue:229.0/255.0 alpha:1.0]];
        
        [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_button_bg"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_button_bg_active"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_button_bg_landscape"] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
        [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"navbar_button_bg_landscape_active"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
        
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"navbar_back_button_bg"] stretchableImageWithLeftCapWidth:14.f topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"navbar_back_button_bg_active"] stretchableImageWithLeftCapWidth:14.f topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"navbar_back_button_bg_landscape"] stretchableImageWithLeftCapWidth:14.f topCapHeight:0] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"navbar_back_button_bg_landscape_active"] stretchableImageWithLeftCapWidth:14.f topCapHeight:0] forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
        
        NSDictionary *titleTextAttributesForStateNormal = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:34.0/255.0 green:34.0/255.0 blue:34.0/255.0 alpha:1.0],
                                                           UITextAttributeTextColor,
                                                           [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0],
                                                           UITextAttributeTextShadowColor,
                                                           [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                           UITextAttributeTextShadowOffset,
                                                           nil];
        
        
        NSDictionary *titleTextAttributesForStateDisabled = [NSDictionary dictionaryWithObjectsAndKeys:
                                                             [UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0],
                                                             UITextAttributeTextColor,
                                                             //          [UIColor colorWithRed:34.0/255.0 green:34.0/255.0 blue:34.0/255.0 alpha:1.0],
                                                             [UIColor UIColorFromHex:0xeeeeee],
                                                             UITextAttributeTextShadowColor,
                                                             [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                             UITextAttributeTextShadowOffset,
                                                             nil];
        
        NSDictionary *titleTextAttributesForStateHighlighted = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                [UIColor colorWithRed:34.0/255.0 green:34.0/255.0 blue:34.0/255.0 alpha:1.0],
                                                                UITextAttributeTextColor,
                                                                [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0],
                                                                UITextAttributeTextShadowColor,
                                                                [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                                UITextAttributeTextShadowOffset,
                                                                nil];
        
        
        [[UIBarButtonItem appearance] setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateNormal];
        [[UIBarButtonItem appearance] setTitleTextAttributes:titleTextAttributesForStateDisabled forState:UIControlStateDisabled];
        [[UIBarButtonItem appearance] setTitleTextAttributes:titleTextAttributesForStateHighlighted forState:UIControlStateHighlighted];
        
        //        [[UISegmentedControl appearance] setTintColor:[UIColor UIColorFromHex:0xeeeeee]];
        [[UISegmentedControl appearance] setTitleTextAttributes:titleTextAttributesForStateNormal forState:UIControlStateNormal];
        [[UISegmentedControl appearance] setTitleTextAttributes:titleTextAttributesForStateDisabled forState:UIControlStateDisabled];
        [[UISegmentedControl appearance] setTitleTextAttributes:titleTextAttributesForStateHighlighted forState:UIControlStateHighlighted];
    }
}

- (void)customizeForiOS7
{
    UIColor *defaultTintColor = self.window.tintColor;
    self.window.tintColor = [WPStyleGuide newKidOnTheBlockBlue];

    [[UINavigationBar appearance] setBarTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
    [[UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil] setTintColor:defaultTintColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor], UITextAttributeFont : [UIFont fontWithName:@"OpenSans-Bold" size:16.0]} ];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"transparent-point"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[UIImage imageNamed:@"transparent-point"]];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeFont: [WPStyleGuide regularTextFont], UITextAttributeTextColor : [UIColor whiteColor]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeFont: [WPStyleGuide regularTextFont], UITextAttributeTextColor : [UIColor lightGrayColor]} forState:UIControlStateDisabled];
    [[UIToolbar appearance] setBarTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
    [[UISwitch appearance] setOnTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)setAppBadge {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)checkWPcomAuthentication {
	NSString *authURL = @"https://wordpress.com/xmlrpc.php";

    WPAccount *account = [WPAccount defaultWordPressComAccount];
	if (account) {
        WPXMLRPCClient *client = [WPXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
        [client callMethod:@"wp.getUsersBlogs"
                parameters:[NSArray arrayWithObjects:account.username, account.password, nil]
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       isWPcomAuthenticated = YES;
                       DDLogInfo(@"Logged in to WordPress.com as %@", account.username);
                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       if ([error.domain isEqualToString:@"XMLRPC"] && error.code == 403) {
                           isWPcomAuthenticated = NO;
                       }
                       DDLogError(@"Error authenticating %@ with WordPress.com: %@", account.username, [error description]);
                   }];
	} else {
		isWPcomAuthenticated = NO;
	}

	if (isWPcomAuthenticated)
		[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"wpcom_authenticated_flag"];
	else
		[[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"wpcom_authenticated_flag"];
}


- (void)checkIfStatsShouldRun {
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
	} else {
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
	
	NSString *deviceModel = [[UIDeviceHardware platform] stringByUrlEncoding];
	NSString *deviceuuid = [[UIDevice currentDevice] wordpressIdentifier];
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	NSString *appversion = [[info objectForKey:@"CFBundleVersion"] stringByUrlEncoding];
	NSLocale *locale = [NSLocale currentLocale];
	NSString *language = [[locale objectForKey: NSLocaleIdentifier] stringByUrlEncoding];
	NSString *osversion = [[[UIDevice currentDevice] systemVersion] stringByUrlEncoding];
	int num_blogs = [Blog countWithContext:[[ContextManager sharedInstance] mainContext]];
	NSString *numblogs = [[NSString stringWithFormat:@"%d", num_blogs] stringByUrlEncoding];
	
	//handle data coming back
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
	
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	if(conn){
		// This is just to keep Analyzer from complaining.
	}

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *theDate = [NSDate date];
	[defaults setObject:theDate forKey:@"statsDate"];
	[defaults synchronize];
}

- (void)checkIfFeedbackShouldBeEnabled
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kWPUserDefaultsFeedbackEnabled: @YES}];
    NSURL *url = [NSURL URLWithString:@"http://api.wordpress.org/iphoneapp/feedback-check/1.0/"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        DDLogVerbose(@"Feedback response received: %@", JSON);
        NSNumber *feedbackEnabled = JSON[@"feedback-enabled"];
        if (feedbackEnabled == nil) {
            feedbackEnabled = @YES;
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:feedbackEnabled.boolValue forKey:kWPUserDefaultsFeedbackEnabled];
        [defaults synchronize];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        DDLogError(@"Error received while checking feedback enabled status: %@", error);

        // Lets be optimistic and turn on feedback by default if this call doesn't work
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:kWPUserDefaultsFeedbackEnabled];
        [defaults synchronize];
    }];
    
    [operation start];
}

- (void)cleanUnusedMediaFileFromTmpDir {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    [context performBlock:^{
        NSError *error;
        NSMutableArray *mediaToKeep = [NSMutableArray array];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Media" inManagedObjectContext:context]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY posts.blog != NULL AND remoteStatusNumber <> %@", @(MediaRemoteStatusSync)];
        [fetchRequest setPredicate:predicate];
        NSArray *mediaObjectsToKeep = [context executeFetchRequest:fetchRequest error:&error];
        if (error != nil) {
            DDLogError(@"Error cleaning up tmp files: %@", [error localizedDescription]);
        }
        //get a references to media files linked in a post
        DDLogInfo(@"%i media items to check for cleanup", [mediaObjectsToKeep count]);
        for (Media *media in mediaObjectsToKeep) {
            [mediaToKeep addObject:media.localURL];
        }
        
        //searches for jpg files within the app temp file
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSArray *contentsOfDir = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
        
        NSError *regexpError = NULL;
        NSRegularExpression *jpeg = [NSRegularExpression regularExpressionWithPattern:@".jpg$" options:NSRegularExpressionCaseInsensitive error:&regexpError];
        
        for (NSString *currentPath in contentsOfDir) {
            if([jpeg numberOfMatchesInString:currentPath options:0 range:NSMakeRange(0, [currentPath length])] > 0) {
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
        }

    }];
}

- (void)toggleExtraDebuggingIfNeeded {
    if (!_listeningForBlogChanges) {
        _listeningForBlogChanges = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogoutOrBlogsChangedNotification:) name:BlogChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogoutOrBlogsChangedNotification:) name:WordPressComApiDidLogoutNotification object:nil];
    }
    
	int num_blogs = [Blog countWithContext:[[ContextManager sharedInstance] mainContext]];
	BOOL authed = [[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_authenticated_flag"] boolValue];
	if (num_blogs == 0 && !authed) {
		// When there are no blogs in the app the settings screen is unavailable.
		// In this case, enable extra_debugging by default to help troubleshoot any issues.
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"orig_extra_debug"] != nil) {
			return; // Already saved. Don't save again or we could loose the original value.
		}
		
		NSString *origExtraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"] ? @"YES" : @"NO";
		[[NSUserDefaults standardUserDefaults] setObject:origExtraDebug forKey:@"orig_extra_debug"];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"extra_debug"];
        ddLogLevel = LOG_LEVEL_VERBOSE;
		[NSUserDefaults resetStandardUserDefaults];
	} else {
		NSString *origExtraDebug = [[NSUserDefaults standardUserDefaults] stringForKey:@"orig_extra_debug"];
		if(origExtraDebug == nil) {
			return;
		}
		
		// Restore the original setting and remove orig_extra_debug.
		[[NSUserDefaults standardUserDefaults] setBool:[origExtraDebug boolValue] forKey:@"extra_debug"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"orig_extra_debug"];
		[NSUserDefaults resetStandardUserDefaults];
        
        if ([origExtraDebug boolValue]) {
            ddLogLevel = LOG_LEVEL_VERBOSE;
        }
	}
}

- (void)handleLogoutOrBlogsChangedNotification:(NSNotification *)notification {
	[self toggleExtraDebuggingIfNeeded];
}

- (void)showNotificationsTab {
    NSInteger notificationsTabIndex = [[self.tabBarController viewControllers] indexOfObject:self.notificationsViewController.navigationController];
    [self.tabBarController setSelectedIndex:notificationsTabIndex];
}


#pragma mark - Push Notification delegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	// Send the deviceToken to our server...
	NSString *myToken = [[[[deviceToken description]
					 stringByReplacingOccurrencesOfString: @"<" withString: @""]
					stringByReplacingOccurrencesOfString: @">" withString: @""]
				   stringByReplacingOccurrencesOfString: @" " withString: @""];

    DDLogInfo(@"Device token received in didRegisterForRemoteNotificationsWithDeviceToken: %@", myToken);
    
	// Store the token
    NSString *previousToken = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if (![previousToken isEqualToString:myToken]) {
         DDLogInfo(@"Device Token has changed! OLD Value %@, NEW value %@", previousToken, myToken);
        [[NSUserDefaults standardUserDefaults] setObject:myToken forKey:kApnsDeviceTokenPrefKey];
        [[WordPressComApi sharedApi] syncPushNotificationInfo]; //synch info again since the device token has changed.
    }

}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	DDLogError(@"Failed to register for push notifications: %@", error);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kApnsDeviceTokenPrefKey];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    WPFLogMethod();
    
    [self handleNotification:userInfo forState:application.applicationState completionHandler:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    WPFLogMethod();
    
    [self handleNotification:userInfo forState:[UIApplication sharedApplication].applicationState completionHandler:completionHandler];
}

- (void)handleNotification:(NSDictionary*)userInfo forState:(UIApplicationState)state completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    DDLogInfo(@"Received push notification:\nPayload: %@\nCurrent Application state: %d", userInfo, state);
    
    switch (state) {
        case UIApplicationStateActive:
            [[WordPressComApi sharedApi] checkForNewUnseenNotifications];
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
            break;
            
        case UIApplicationStateInactive:
            _hasRecordedApplicationOpenedEvent = YES;
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAppOpenedDueToPushNotification];

            [self openNotificationScreenWithOptions:userInfo];
            break;
            
        case UIApplicationStateBackground:
            _hasRecordedApplicationOpenedEvent = YES;
            [WPMobileStats trackEventForSelfHostedAndWPCom:StatsEventAppOpenedDueToPushNotification];

            [self openNotificationScreenWithOptions:userInfo];
            
            if (completionHandler) {
                [Note getNewNotificationswithContext:[[ContextManager sharedInstance] mainContext] success:^(BOOL hasNewNotes) {
                    DDLogInfo(@"notification fetch completion handler completed with new notes: %@", hasNewNotes ? @"YES" : @"NO");
                    if (hasNewNotes) {
                        completionHandler(UIBackgroundFetchResultNewData);
                    } else {
                        completionHandler(UIBackgroundFetchResultNewData);
                    }
                } failure:^(NSError *error) {
                    DDLogError(@"notification fetch completion handler failed with error: %@", error);
                    completionHandler(UIBackgroundFetchResultFailed);
                }];
            }
            break;
        default:
            break;
    }
}

- (void)registerForPushNotifications {
    if (isWPcomAuthenticated) {
        [[UIApplication sharedApplication]
         registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                             UIRemoteNotificationTypeSound |
                                             UIRemoteNotificationTypeAlert)];
    }
}

- (void)unregisterApnsToken {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:kApnsDeviceTokenPrefKey];
    if( nil == token ) return; //no apns token available
    
    if(![[WordPressComApi sharedApi] hasCredentials])
        return;
    
    NSString *authURL = kNotificationAuthURL;   	
    WPAccount *account = [WPAccount defaultWordPressComAccount];
	if (account) {
#ifdef DEBUG
        NSNumber *sandbox = [NSNumber numberWithBool:YES];
#else
        NSNumber *sandbox = [NSNumber numberWithBool:NO];
#endif
        NSArray *parameters = @[account.username,
                                account.password,
                                token,
                                [[UIDevice currentDevice] wordpressIdentifier],
                                @"apple",
                                sandbox,
#ifdef INTERNAL_BUILD
                                @"org.wordpress.internal"
#endif
                                ];
        
        WPXMLRPCClient *api = [[WPXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
        [api setAuthorizationHeaderWithToken:[[WordPressComApi sharedApi] authToken]];
        [api callMethod:@"wpcom.mobile_push_unregister_token"
             parameters:parameters
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    DDLogInfo(@"Unregistered token %@", token);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    DDLogError(@"Couldn't unregister token: %@", [error localizedDescription]);
                }];
    }
}

- (void)openNotificationScreenWithOptions:(NSDictionary *)remoteNotif {
    DDLogInfo(@"Received new notification: %@", remoteNotif);
    [self showNotificationsTab];

    // TODO: Open comment view here
//    if ([remoteNotif objectForKey:@"blog_id"] && [remoteNotif objectForKey:@"comment_id"]) {
//        MP6SidebarViewController *sidebar = (MP6SidebarViewController *)self.panelNavigationController.masterViewController;
//        [sidebar showCommentWithId:[[remoteNotif objectForKey:@"comment_id"] numericValue] blogId:[[remoteNotif objectForKey:@"blog_id"] numericValue]];
//    } else if ([remoteNotif objectForKey:@"type"] == nil) {
//        DDLogWarn(@"Got unsupported notification: %@", remoteNotif);
//    }
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
							   cancelButtonTitle:NSLocalizedString(@"OK", @"OK button label (shown in popups).")
							   otherButtonTitles:nil];
	[errorAlert show];
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection {
	NSString *statsDataString = [[NSString alloc] initWithData:statsData encoding:NSUTF8StringEncoding];
    statsDataString = [[statsDataString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:0];
	NSString *appversion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    if ([statsDataString compare:appversion options:NSNumericSearch] > 0) {
        DDLogInfo(@"There's a new version: %@", statsDataString);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Update Available", @"Popup title to highlight a new version of the app being available.")
                                                        message:NSLocalizedString(@"A new version of WordPress for iOS is now available", @"Generic popup message to highlight a new version of the app being available.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss button label.")
                                              otherButtonTitles:NSLocalizedString(@"Update Now", @"Popup 'update' button to highlight a new version of the app being available. The button takes you to the app store on the device, and should be actionable."), nil];
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
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex { 
	[self setAlertRunning:NO];
	
    if (alertView.tag == 102) { // Update alert
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/wordpress/id335703880?mt=8&ls=1"]];
        }
    } else if (alertView.tag == kNotificationNewComment) {
        if (buttonIndex == 1) {
            [self openNotificationScreenWithOptions:lastNotificationInfo];
             lastNotificationInfo = nil;
        }
    } else if (alertView.tag == kNotificationNewSocial) {
        if (buttonIndex == 1) {
            [self showNotificationsTab];
            lastNotificationInfo = nil;
        }
	} else {
		//Need Help Alert
		switch(buttonIndex) {
			case 0: {
				SupportViewController *supportViewController = [[SupportViewController alloc] init];
                UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:supportViewController];
                aNavigationController.navigationBar.translucent = NO;
                if (IS_IPAD) {
                    aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                    aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                }
                
                UIViewController *presenter = self.tabBarController;
                if (presenter.presentedViewController) {
                    presenter = presenter.presentedViewController;
                }
                [presenter presentViewController:aNavigationController animated:YES completion:nil];

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

- (void)crashlytics:(Crashlytics *)crashlytics didDetectCrashDuringPreviousExecution:(id<CLSCrashReport>)crash
{
    WPFLogMethod();
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger crashCount = [defaults integerForKey:@"crashCount"];
    crashCount += 1;
    [defaults setInteger:crashCount forKey:@"crashCount"];
    [defaults synchronize];
    [WPMobileStats trackEventForSelfHostedAndWPCom:@"Crashed" properties:@{@"crash_id": crash.identifier}];
}

- (void)resetStatRelatedVariables
{
    [WPMobileStats clearPropertiesForAllEvents];
    _hasRecordedApplicationOpenedEvent = NO;
}

@end
