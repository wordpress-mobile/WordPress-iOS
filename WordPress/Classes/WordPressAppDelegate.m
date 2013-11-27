/*
 * WordPressAppDelegate.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import <Crashlytics/Crashlytics.h>
#import <GooglePlus/GooglePlus.h>
#import "WordPressAppDelegate.h"
#import "Reachability.h"
#import "NSString+Helpers.h"
#import "Media.h"
#import "CameraPlusPickerManager.h"
#import "UIDevice+WordPressIdentifier.h"
#import "WordPressComApi.h"
#import "WordPressComApiCredentials.h"
#import "PocketAPI.h"
#import "WPAccount.h"
#import "SupportViewController.h"
#import "ContextManager.h"
#import "ReaderPostsViewController.h"
#import "NotificationsViewController.h"
#import "BlogListViewController.h"
#import "LoginViewController.h"
#import <CrashlyticsLumberjack/CrashlyticsLogger.h>
#import <HockeySDK/HockeySDK.h>
#import "NotificationsManager.h"
#import <DDFileLogger.h>
#import <AFNetworking/AFNetworking.h>
#import "ContextManager.h"

#if DEBUG
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#endif

int ddLogLevel = LOG_LEVEL_INFO;
NSInteger const UpdateCheckAlertViewTag = 102;
NSString * const WPTabBarRestorationID = @"WPTabBarID";
NSString * const WPBlogListNavigationRestorationID = @"WPBlogListNavigationID";
NSString * const WPReaderNavigationRestorationID = @"WPReaderNavigationID";
NSString * const WPNotificationsNavigationRestorationID = @"WPNotificationsNavigationID";


@interface WordPressAppDelegate () <CrashlyticsDelegate, UIAlertViewDelegate, BITHockeyManagerDelegate>

@property (nonatomic, assign) BOOL listeningForBlogChanges;
@property (nonatomic, strong) NotificationsViewController *notificationsViewController;
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;
@property (strong, nonatomic) DDFileLogger *fileLogger;

@end

@implementation WordPressAppDelegate

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate {
    return (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
}


#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Crash reporting, logging, debugging
    [self configureHockeySDK];
    [self configureCrashlytics];
    [self configureLogging];
    [self printDebugLaunchInfo];
    [self toggleExtraDebuggingIfNeeded];
    [self removeCredentialsForDebug];

    // Stats and feedback
    [WPMobileStats initializeStats];
    [[GPPSignIn sharedInstance] setClientID:[WordPressComApiCredentials googlePlusClientId]];
    [self checkIfStatsShouldSendAndUpdateCheck];
    [self checkIfFeedbackShouldBeEnabled];
    
    // Networking setup
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [self setupReachability];
    [self setupUserAgent];
    [self checkWPcomAuthentication];
    [self setupSingleSignOn];

    [self customizeAppearance];

    CGRect bounds = [[UIScreen mainScreen] bounds];
    [self.window setFrame:bounds];
    [self.window setBounds:bounds]; // for good measure.
    
    self.window.backgroundColor = [UIColor blackColor];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    [self showWelcomeScreenIfNeeded];

    // Push notifications
    [NotificationsManager registerForPushNotifications];
    [NotificationsManager handleNotificationForApplicationLaunch:launchOptions];
    
	//listener for XML-RPC errors
	//in the future we could put the errors message in a dedicated screen that users can bring to front when samething went wrong, and can take a look at the error msg.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:kXML_RPC_ERROR_OCCURS object:nil];
	
	// another notification message came from comments --> CommentUploadFailed
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:@"CommentUploadFailed" object:nil];

    // another notification message came from WPWebViewController
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationErrorAlert:) name:@"OpenWebPageFailed" object:nil];
    
    // Deferred tasks to speed up app launch
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self changeCurrentDirectory];
        [WordPressAppDelegate fixKeychainAccess];
        [[PocketAPI sharedAPI] setConsumerKey:[WordPressComApiCredentials pocketConsumerKey]];
        [self cleanUnusedMediaFileFromTmpDir];
    });
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[BITHockeyManager sharedHockeyManager].authenticator handleOpenURL:url
                                                          sourceApplication:sourceApplication
                                                                 annotation:annotation]) {
        return YES;
    }

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
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [WPMobileStats endSession];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

    [WPMobileStats trackEventForWPComWithSavedProperties:StatsEventAppClosed];
    [WPMobileStats pauseSession];
    
    // Let the app finish any uploads that are in progress
    UIApplication *app = [UIApplication sharedApplication];
    if (_bgTask != UIBackgroundTaskInvalid) {
        [app endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }
    
    _bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        // Synchronize the cleanup call on the main thread in case
        // the task actually finishes at around the same time.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_bgTask != UIBackgroundTaskInvalid)
            {
                [app endBackgroundTask:_bgTask];
                _bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [WPMobileStats resumeSession];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    
    [WPMobileStats recordAppOpenedForEvent:StatsEventAppOpened];
    
    // Clear notifications badge and update server
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [[WordPressComApi sharedApi] syncPushNotificationInfo];
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return YES;
}


#pragma mark - Push Notification delegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	[NotificationsManager registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	[NotificationsManager registrationDidFail:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    WPFLogMethod();
    
    [NotificationsManager handleNotification:userInfo forState:application.applicationState completionHandler:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    WPFLogMethod();
    
    [NotificationsManager handleNotification:userInfo forState:[UIApplication sharedApplication].applicationState completionHandler:completionHandler];
}


#pragma mark - Custom methods

- (void)showWelcomeScreenIfNeeded {
    if ([self noBlogsAndNoWordPressDotComAccount]) {
        [WordPressAppDelegate wipeAllKeychainItems];
        
        LoginViewController *welcomeViewController = [[LoginViewController alloc] init];
        UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:welcomeViewController];
        aNavigationController.navigationBar.translucent = NO;
        aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self.window.rootViewController presentViewController:aNavigationController animated:NO completion:nil];
    }
}

- (BOOL)noBlogsAndNoWordPressDotComAccount {
    NSInteger blogCount = [Blog countWithContext:[[ContextManager sharedInstance] mainContext]];
    return blogCount == 0 && ![WPAccount defaultWordPressComAccount];
}

- (void)customizeAppearance
{
    UIColor *defaultTintColor = self.window.tintColor;
    self.window.tintColor = [WPStyleGuide newKidOnTheBlockBlue];
    
    [[UINavigationBar appearance] setBarTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
    [[UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil] setTintColor:defaultTintColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"OpenSans-Bold" size:16.0]} ];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"transparent-point"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[UIImage imageNamed:@"transparent-point"]];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [UIColor lightGrayColor]} forState:UIControlStateDisabled];
    [[UIToolbar appearance] setBarTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
    [[UISwitch appearance] setOnTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}


#pragma mark - Tab bar setup

- (UITabBarController *)tabBarController {
    _tabBarController = [[UITabBarController alloc] init];
    _tabBarController.restorationIdentifier = WPTabBarRestorationID;
    [_tabBarController.tabBar setTranslucent:NO];

    self.readerPostsViewController = [[ReaderPostsViewController alloc] init];
    UINavigationController *readerNavigationController = [[UINavigationController alloc] initWithRootViewController:self.readerPostsViewController];
    readerNavigationController.navigationBar.translucent = NO;
    readerNavigationController.tabBarItem.image = [UIImage imageNamed:@"icon-tab-reader"];
    readerNavigationController.restorationIdentifier = WPReaderNavigationRestorationID;
    self.readerPostsViewController.title = @"Reader";
    
    self.notificationsViewController = [[NotificationsViewController alloc] init];
    UINavigationController *notificationsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.notificationsViewController];
    notificationsNavigationController.navigationBar.translucent = NO;
    notificationsNavigationController.tabBarItem.image = [UIImage imageNamed:@"icon-tab-notifications"];
    notificationsNavigationController.restorationIdentifier = WPNotificationsNavigationRestorationID;
    self.notificationsViewController.title = @"Notifications";
    
    BlogListViewController *blogListViewController = [[BlogListViewController alloc] init];
    UINavigationController *blogListNavigationController = [[UINavigationController alloc] initWithRootViewController:blogListViewController];
    blogListNavigationController.navigationBar.translucent = NO;
    blogListNavigationController.tabBarItem.image = [UIImage imageNamed:@"icon-tab-blogs"];
    blogListNavigationController.restorationIdentifier = WPBlogListNavigationRestorationID;
    blogListViewController.title = @"My Blogs";
    _tabBarController.viewControllers = [NSArray arrayWithObjects:blogListNavigationController, readerNavigationController, notificationsNavigationController, nil];
    
    [_tabBarController setSelectedViewController:readerNavigationController];
    
    return _tabBarController;
}

- (void)showNotificationsTab {
    NSInteger notificationsTabIndex = [[self.tabBarController viewControllers] indexOfObject:self.notificationsViewController.navigationController];
    [self.tabBarController setSelectedIndex:notificationsTabIndex];
}

#pragma mark - Global Alerts

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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[self setAlertRunning:NO];
	
    if (alertView.tag == 102) { // Update alert
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/wordpress/id335703880?mt=8&ls=1"]];
        }
    } else if (alertView.tag == kNotificationNewComment) {
        if (buttonIndex == 1) {
            [self showNotificationsTab];
        }
    } else if (alertView.tag == kNotificationNewSocial) {
        if (buttonIndex == 1) {
            [self showNotificationsTab];
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


#pragma mark - Application directories

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)changeCurrentDirectory {
    // Set current directory for WordPress app
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *currentDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"wordpress"];
    
	BOOL isDir;
	if (![fileManager fileExistsAtPath:currentDirectoryPath isDirectory:&isDir] || !isDir) {
		[fileManager createDirectoryAtPath:currentDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
	[fileManager changeCurrentDirectoryPath:currentDirectoryPath];
}


#pragma mark - Stats and feedback

- (void)checkIfStatsShouldSendAndUpdateCheck {
    if (NO) { // Switch this to YES to debug stats/update check
        [self sendStatsAndCheckForAppUpdate];
        return;
    }
	//check if statsDate exists in user defaults, if not, add it and run stats since this is obviously the first time
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	//[defaults setObject:nil forKey:@"statsDate"];  // Uncomment this line to force stats.
	if (![defaults objectForKey:@"statsDate"]){
		NSDate *theDate = [NSDate date];
		[defaults setObject:theDate forKey:@"statsDate"];
		[self sendStatsAndCheckForAppUpdate];
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
			[self sendStatsAndCheckForAppUpdate];
		}
	}
}

- (void)sendStatsAndCheckForAppUpdate {
	//generate and post the stats data
	/*
	 - device_uuid – A unique identifier to the iPhone/iPod that the app is installed on.
	 - app_version – the version number of the WP iPhone app
	 - language – language setting for the device. What does that look like? Is it EN or English?
	 - os_version – the version of the iPhone/iPod OS for the device
	 - num_blogs – number of blogs configured in the WP iPhone app
	 - device_model - kind of device on which the WP iPhone app is installed
	 */
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	NSLocale *locale = [NSLocale currentLocale];
	NSInteger blogCount = [Blog countWithContext:[[ContextManager sharedInstance] mainContext]];
    NSDictionary *parameters = @{@"device_uuid": [[UIDevice currentDevice] wordpressIdentifier],
                                 @"app_version": [[info objectForKey:@"CFBundleVersion"] stringByUrlEncoding],
                                 @"language": [[locale objectForKey: NSLocaleIdentifier] stringByUrlEncoding],
                                 @"os_version": [[[UIDevice currentDevice] systemVersion] stringByUrlEncoding],
                                 @"num_blogs": [[NSString stringWithFormat:@"%d", blogCount] stringByUrlEncoding],
                                 @"device_model": [[UIDeviceHardware platform] stringByUrlEncoding]};

    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://api.wordpress.org/iphoneapp/update-check/1.0/"]];
    client.parameterEncoding = AFFormURLParameterEncoding;
    [client postPath:@"" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSData *responseObject) {
        NSString *statsDataString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
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
    } failure:nil];
	
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


#pragma mark - Crash reporting

- (void)configureCrashlytics {
#if DEBUG
    return;
#endif
#ifdef INTERNAL_BUILD
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

- (void)setCommonCrashlyticsParameters
{
    [Crashlytics setObjectValue:[NSNumber numberWithBool:[[WordPressComApi sharedApi] hasCredentials]] forKey:@"logged_in"];
    [Crashlytics setObjectValue:@([[WordPressComApi sharedApi] hasCredentials]) forKey:@"connected_to_dotcom"];
    [Crashlytics setObjectValue:@([Blog countWithContext:[[ContextManager sharedInstance] mainContext]]) forKey:@"number_of_blogs"];
}

- (void)configureHockeySDK {
#ifndef INTERNAL_BUILD
    return;
#endif
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:[WordPressComApiCredentials hockeyappAppId]
                                                           delegate:self];
    [[BITHockeyManager sharedHockeyManager].authenticator setIdentificationType:BITAuthenticatorIdentificationTypeDevice];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
}

#pragma mark - BITCrashManagerDelegate

- (NSString *)applicationLogForCrashManager:(BITCrashManager *)crashManager {
    NSString *description = [self getLogFilesContentWithMaxSize:5000]; // 5000 bytes should be enough!
    if ([description length] == 0) {
        return nil;
    } else {
        return description;
    }
}

#pragma mark - Media cleanup

- (void)cleanUnusedMediaFileFromTmpDir {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

    NSManagedObjectContext *context = [[ContextManager sharedInstance] backgroundContext];
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


#pragma mark - Networking setup, User agents

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

- (void)setupSingleSignOn {
    if ([[WPAccount defaultWordPressComAccount] username]) {
        [[WPComOAuthController sharedController] setWordPressComUsername:[[WPAccount defaultWordPressComAccount] username]];
        [[WPComOAuthController sharedController] setWordPressComPassword:[[WPAccount defaultWordPressComAccount] password]];
    }
}

- (void)setupReachability {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    // Set the wpcom availability to YES to avoid issues with lazy reachibility notifier
    self.wpcomAvailable = YES;
    // Same for general internet connection
    self.connectionAvailable = YES;
    
    // allocate the internet reachability object
    _internetReachability = [Reachability reachabilityForInternetConnection];

    self.connectionAvailable = [_internetReachability isReachable];
    // set the blocks
    _internetReachability.reachableBlock = ^(Reachability*reach)
    {
        DDLogInfo(@"Internet connection is back");
        self.connectionAvailable = YES;
    };
    _internetReachability.unreachableBlock = ^(Reachability*reach)
    {
        DDLogInfo(@"No internet connection");
        self.connectionAvailable = NO;
    };
    // start the notifier which will cause the reachability object to retain itself!
    [_internetReachability startNotifier];
    
    // allocate the WP.com reachability object
    _wpcomReachability = [Reachability reachabilityWithHostname:@"wordpress.com"];
    // set the blocks
    _wpcomReachability.reachableBlock = ^(Reachability*reach)
    {
        DDLogInfo(@"Connection to WordPress.com is back");
        self.wpcomAvailable = YES;
    };
    _wpcomReachability.unreachableBlock = ^(Reachability*reach)
    {
        DDLogInfo(@"No connection to WordPress.com");
        self.wpcomAvailable = NO;
    };
    // start the notifier which will cause the reachability object to retain itself!
    [_wpcomReachability startNotifier];
#pragma clang diagnostic pop
}

- (void)checkWPcomAuthentication {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_authenticated_flag"] != nil) {
        NSString *tempIsAuthenticated = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_authenticated_flag"];
        if ([tempIsAuthenticated isEqualToString:@"1"]) {
            self.isWPcomAuthenticated = YES;
        }
    }
    
	NSString *authURL = @"https://wordpress.com/xmlrpc.php";
    WPAccount *account = [WPAccount defaultWordPressComAccount];
	if (account) {
        WPXMLRPCClient *client = [WPXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:authURL]];
        [client callMethod:@"wp.getUsersBlogs"
                parameters:[NSArray arrayWithObjects:account.username, account.password, nil]
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       self.isWPcomAuthenticated = YES;
                       DDLogInfo(@"Logged in to WordPress.com as %@", account.username);
                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       if ([error.domain isEqualToString:@"XMLRPC"] && error.code == 403) {
                           self.isWPcomAuthenticated = NO;
                       }
                       DDLogError(@"Error authenticating %@ with WordPress.com: %@", account.username, [error description]);
                   }];
	} else {
		self.isWPcomAuthenticated = NO;
	}
    
	if (self.isWPcomAuthenticated) {
		[[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"wpcom_authenticated_flag"];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"wpcom_authenticated_flag"];
    }
}


#pragma mark - Keychain

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
    DDLogVerbose(@"End keychain fixing");
}


#pragma mark - Debugging and logging

- (void)printDebugLaunchInfo {
    UIDevice *device = [UIDevice currentDevice];
    NSInteger crashCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"crashCount"];
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
}

- (void)removeCredentialsForDebug {
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
}

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
    
#ifndef INTERNAL_BUILD
    [DDLog addLogger:[CrashlyticsLogger sharedInstance]];
#endif
    
    BOOL extraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"];
    if (extraDebug) {
        ddLogLevel = LOG_LEVEL_VERBOSE;
    }
}

- (DDFileLogger *)fileLogger {
    if (_fileLogger) {
        return _fileLogger;
    }
    _fileLogger = [[DDFileLogger alloc] init];
    _fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    _fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:_fileLogger];
    return _fileLogger;
}

// get the log content with a maximum byte size
- (NSString *) getLogFilesContentWithMaxSize:(NSInteger)maxSize {
    NSMutableString *description = [NSMutableString string];
    
    NSArray *sortedLogFileInfos = [[self.fileLogger logFileManager] sortedLogFileInfos];
    NSInteger count = [sortedLogFileInfos count];
    
    // we start from the last one
    for (NSInteger index = 0; index < count; index++) {
        DDLogFileInfo *logFileInfo = [sortedLogFileInfos objectAtIndex:index];
        
        NSData *logData = [[NSFileManager defaultManager] contentsAtPath:[logFileInfo filePath]];
        if ([logData length] > 0) {
            NSString *result = [[NSString alloc] initWithBytes:[logData bytes]
                                                        length:[logData length]
                                                      encoding: NSUTF8StringEncoding];
            
            [description appendString:result];
        }
    }
    
    if ([description length] > maxSize) {
        description = (NSMutableString *)[description substringWithRange:NSMakeRange([description length] - maxSize - 1, maxSize)];
    }
    
    return description;
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

@end
