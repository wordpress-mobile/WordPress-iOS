#import <AFNetworking/UIKit+AFNetworking.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <Crashlytics/Crashlytics.h>
#import <CrashlyticsLumberjack/CrashlyticsLogger.h>
#import <DDFileLogger.h>
#import <GooglePlus/GooglePlus.h>
#import <HockeySDK/HockeySDK.h>
#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import <Simperium/Simperium.h>
#import <WordPress-iOS-Shared/WPFontManager.h>
#import <WordPress-AppbotX/ABX.h>

#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "Media.h"
#import "Notification.h"
#import "NotificationsManager.h"
#import "NSString+Helpers.h"
#import "NSString+HTML.h"
#import "PocketAPI.h"
#import "ReaderPost.h"
#import "UIDevice+Helpers.h"
#import "WordPressComApiCredentials.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "BlogService.h"
#import "WPImageOptimizer.h"
#import "ReaderPostService.h"
#import "ReaderTopicService.h"
#import "SVProgressHUD.h"
#import "TodayExtensionService.h"

#import "WPTabBarController.h"
#import "BlogListViewController.h"
#import "BlogDetailsViewController.h"
#import "MeViewController.h"
#import "PostsViewController.h"
#import "WPPostViewController.h"
#import "WPLegacyEditPostViewController.h"
#import "WPWhatsNew.h"
#import "LoginViewController.h"
#import "NotificationsViewController.h"
#import "ReaderViewController.h"
#import "SupportViewController.h"
#import "StatsViewController.h"
#import "Constants.h"
#import "UIImage+Util.h"
#import "NSBundle+VersionNumberHelper.h"
#import "NSProcessInfo+Util.h"
#import "WPAppAnalytics.h"

#import "AppRatingUtility.h"
#import "HelpshiftUtils.h"

#import "Reachability.h"
#import "WordPress-Swift.h"

#ifdef LOOKBACK_ENABLED
#import <Lookback/Lookback.h>
#endif

#if DEBUG
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#endif

int ddLogLevel                                                  = LOG_LEVEL_INFO;
static NSString * const MustShowWhatsNewPopup                   = @"MustShowWhatsNewPopup";

@interface WordPressAppDelegate () <UITabBarControllerDelegate, CrashlyticsDelegate, UIAlertViewDelegate, BITHockeyManagerDelegate>

@property (nonatomic, strong, readwrite) WPAppAnalytics                 *analytics;
@property (nonatomic, strong, readwrite) Reachability                   *internetReachability;
@property (nonatomic, strong, readwrite) DDFileLogger                   *fileLogger;
@property (nonatomic, strong, readwrite) Simperium                      *simperium;
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier     bgTask;
@property (nonatomic, assign, readwrite) BOOL                           connectionAvailable;

/**
 *  @brief      Flag that signals wether Whats New is on screen or not.
 *  @details    Won't be necessary once WPWhatsNew is changed to inherit from UIViewController
 *              https://github.com/wordpress-mobile/WordPress-iOS/issues/3218
 */
@property (nonatomic, assign, readwrite) BOOL                           wasWhatsNewShown;

@end

@implementation WordPressAppDelegate

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate
{
    return (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [WordPressAppDelegate fixKeychainAccess];

    // Simperium: Wire CoreData Stack
    [self configureSimperiumWithLaunchOptions:launchOptions];

    // Crash reporting, logging
    [self configureLogging];
    [self configureHockeySDK];
    [self configureCrashlytics];
    [self initializeAppRatingUtility];
    
    // Analytics
    self.analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:^NSString*{
        return [self currentlySelectedScreen];
    }];

    // Start Simperium
    [self loginSimperium];

    // Local Notifications
    [self listenLocalNotifications];
    
    // Debugging
    [self printDebugLaunchInfoWithLaunchOptions:launchOptions];
    [self toggleExtraDebuggingIfNeeded];
    [self removeCredentialsForDebug];

    // Stop Storing WordPress.com passwords
    [self removeWordPressComPassword];
    
    // Stats and feedback    
    [SupportViewController checkIfFeedbackShouldBeEnabled];

    [HelpshiftUtils setup];

    [[GPPSignIn sharedInstance] setClientID:[WordPressComApiCredentials googlePlusClientId]];

    // Networking setup
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [self setupReachability];
    [self setupUserAgent];
    [self setupSingleSignOn];

    [self customizeAppearance];
    
    // Push notifications
    [NotificationsManager registerForPushNotifications];

    // Deferred tasks to speed up app launch
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self changeCurrentDirectory];
        [[PocketAPI sharedAPI] setConsumerKey:[WordPressComApiCredentials pocketConsumerKey]];
        [self cleanUnusedMediaFileFromTmpDir];
    });
    
    // Configure Today Widget
    [self determineIfTodayWidgetIsConfiguredAndShowAppropriately];

    if ([WPPostViewController makeNewEditorAvailable]) {
        [self setMustShowWhatsNewPopup:YES];
    }
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    [self.window setFrame:bounds];
    [self.window setBounds:bounds]; // for good measure.
    self.window.rootViewController = [WPTabBarController sharedInstance];

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    DDLogVerbose(@"didFinishLaunchingWithOptions state: %d", application.applicationState);

    // Launched by tapping a notification
    if (application.applicationState == UIApplicationStateActive) {
        [NotificationsManager handleNotificationForApplicationLaunch:launchOptions];
    }

    [self.window makeKeyAndVisible];
    [self showWelcomeScreenIfNeededAnimated:NO];
    [self setupLookback];
    [self setupAppbotX];

    return YES;
}

- (void)setupLookback
{
#ifdef LOOKBACK_ENABLED
    // Kick this off on a background thread so as to not slow down the app initialization
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if ([WordPressComApiCredentials lookbackToken].length > 0) {
            [Lookback setupWithAppToken:[WordPressComApiCredentials lookbackToken]];
            [[NSUserDefaults standardUserDefaults] registerDefaults:@{WPInternalBetaShakeToPullUpFeedbackKey: @YES}];
            [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:LookbackCameraEnabledSettingsKey];
            [Lookback lookback].shakeToRecord = [[NSUserDefaults standardUserDefaults] boolForKey:WPInternalBetaShakeToPullUpFeedbackKey];
            
            // Setup Lookback to fire when the user holds down with three fingers for around 3 seconds
            dispatch_async(dispatch_get_main_queue(), ^{
                UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(lookbackGestureRecognized:)];
                recognizer.minimumPressDuration = 3;
                recognizer.cancelsTouchesInView = NO;
#if TARGET_IPHONE_SIMULATOR
                recognizer.numberOfTouchesRequired = 2;
#else
                recognizer.numberOfTouchesRequired = 3;
#endif
                [[UIApplication sharedApplication].keyWindow addGestureRecognizer:recognizer];
            });
            
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
            WPAccount *account = [accountService defaultWordPressComAccount];
            [Lookback lookback].userIdentifier = account.username;
        }
    });
#endif
}

- (void)setupAppbotX
{
    if ([WordPressComApiCredentials appbotXAPIKey].length > 0) {
        [[ABXApiClient instance] setApiKey:[WordPressComApiCredentials appbotXAPIKey]];
    }
}

- (void)lookbackGestureRecognized:(UILongPressGestureRecognizer *)sender
{
#ifdef LOOKBACK_ENABLED
    if (sender.state == UIGestureRecognizerStateBegan) {
        [LookbackRecordingViewController presentOntoScreenAnimated:YES];
    }
#endif
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    BOOL returnValue = NO;

    if ([[BITHockeyManager sharedHockeyManager].authenticator handleOpenURL:url
                                                          sourceApplication:sourceApplication
                                                                 annotation:annotation]) {
        returnValue = YES;
    }

    if ([[GPPShare sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation]) {
        returnValue = YES;
    }

    if ([[PocketAPI sharedAPI] handleOpenURL:url]) {
        returnValue = YES;
    }

    if ([WordPressApi handleOpenURL:url]) {
        returnValue = YES;
    }

    if ([url isKindOfClass:[NSURL class]] && [[url absoluteString] hasPrefix:WPCOM_SCHEME]) {
        NSString *URLString = [url absoluteString];
        DDLogInfo(@"Application launched with URL: %@", URLString);

        if ([URLString rangeOfString:@"newpost"].length) {
            returnValue = [self handleNewPostRequestWithURL:url];
        } else if ([URLString rangeOfString:@"viewpost"].length) {
            // View the post specified by the shared blog ID and post ID
            NSDictionary *params = [[url query] dictionaryFromQueryString];
            
            if (params.count) {
                NSNumber *blogId = [params numberForKey:@"blogId"];
                NSNumber *postId = [params numberForKey:@"postId"];

                WPTabBarController *tabBarController = [WPTabBarController sharedInstance];
                [tabBarController.readerViewController.navigationController popToRootViewControllerAnimated:NO];
                [tabBarController showReaderTab];
                [tabBarController.readerViewController openPost:postId onBlog:blogId];
                
                returnValue = YES;
            }
        } else if ([URLString rangeOfString:@"viewstats"].length) {
            // View the post specified by the shared blog ID and post ID
            NSDictionary *params = [[url query] dictionaryFromQueryString];
            
            if (params.count) {
                NSNumber *siteId = [params numberForKey:@"siteId"];
                
                BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
                Blog *blog = [blogService blogByBlogId:siteId];
                
                if (blog) {
                    returnValue = YES;
                    
                    StatsViewController *statsViewController = [[StatsViewController alloc] init];
                    statsViewController.blog = blog;
                    statsViewController.dismissBlock = ^{
                        [[WPTabBarController sharedInstance] dismissViewControllerAnimated:YES completion:nil];
                    };
                    
                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:statsViewController];
                    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
                    navController.navigationBar.translucent = NO;
                    [[WPTabBarController sharedInstance] presentViewController:navController animated:YES completion:nil];
                }
                
            }
        } else if ([URLString rangeOfString:@"debugging"].length) {
            NSDictionary *params = [[url query] dictionaryFromQueryString];

            if (params.count > 0) {
                NSString *debugType = [params stringForKey:@"type"];
                NSString *debugKey = [params stringForKey:@"key"];

                if ([[WordPressComApiCredentials debuggingKey] isEqualToString:@""] || [debugKey isEqualToString:@""]) {
                    return NO;
                }

                if ([debugKey isEqualToString:[WordPressComApiCredentials debuggingKey]]) {
                    if ([debugType isEqualToString:@"crashlytics_crash"]) {
                        [[Crashlytics sharedInstance] crash];
                    }
                }
            }
		}
    }

    return returnValue;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

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
            if (_bgTask != UIBackgroundTaskInvalid) {
                [app endBackgroundTask:_bgTask];
                _bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
}

- (NSString *)currentlySelectedScreen
{
    // Check if the post editor or login view is up
    UIViewController *rootViewController = self.window.rootViewController;
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *firstViewController = [navController.viewControllers firstObject];
        if ([firstViewController isKindOfClass:[WPPostViewController class]]) {
            return @"Post Editor";
        } else if ([firstViewController isKindOfClass:[LoginViewController class]]) {
            return @"Login View";
        }
    }

    return [[WPTabBarController sharedInstance] currentlySelectedScreen];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    
    [self showWhatsNewIfNeeded];
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

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [NotificationsManager registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [NotificationsManager registrationDidFail:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    DDLogMethod();

    [NotificationsManager handleNotification:userInfo forState:application.applicationState completionHandler:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DDLogMethod();

    [NotificationsManager handleNotification:userInfo forState:[UIApplication sharedApplication].applicationState completionHandler:completionHandler];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier
                                        forRemoteNotification:(NSDictionary *)remoteNotification
                                            completionHandler:(void (^)())completionHandler
{
    [NotificationsManager handleActionWithIdentifier:identifier forRemoteNotification:remoteNotification];
    
    completionHandler();
}

#pragma mark - OpenURL helpers

/**
 *  @brief      Handle the a new post request by URL.
 *  
 *  @param      url     The URL with the request info.  Cannot be nil.
 *
 *  @return     YES if the request was handled, NO otherwise.
 */
- (BOOL)handleNewPostRequestWithURL:(NSURL*)url
{
    NSParameterAssert([url isKindOfClass:[NSURL class]]);
    
    BOOL handled = NO;
    
    // Create a new post from data shared by a third party application.
    NSDictionary *params = [[url query] dictionaryFromQueryString];
    DDLogInfo(@"App launched for new post with params: %@", params);
    
    params = [self sanitizeNewPostParameters:params];
    
    if ([params count]) {
        [[WPTabBarController sharedInstance] showPostTabWithOptions:params];
        handled = YES;
    }
	
    return handled;
}

/**
 *	@brief		Sanitizes a 'new post' parameters dictionary.
 *	@details	Prevent HTML injections like the one in:
 *				https://github.com/wordpress-mobile/WordPress-iOS-Editor/issues/211
 *
 *	@param		parameters		The new post parameters to sanitize.  Cannot be nil.
 *
 *  @returns    The sanitized dictionary.
 */
- (NSDictionary*)sanitizeNewPostParameters:(NSDictionary*)parameters
{
    NSParameterAssert([parameters isKindOfClass:[NSDictionary class]]);
	
    NSUInteger parametersCount = [parameters count];
    
    NSMutableDictionary* sanitizedDictionary = [[NSMutableDictionary alloc] initWithCapacity:parametersCount];
    
    for (NSString* key in [parameters allKeys])
    {
        NSString* value = [parameters objectForKey:key];
        
        if ([key isEqualToString:kWPNewPostURLParamContentKey]) {
            value = [value stringByStrippingHTML];
        } else if ([key isEqualToString:kWPNewPostURLParamTagsKey]) {
            value = [value stringByStrippingHTML];
        }
        
        [sanitizedDictionary setObject:value forKey:key];
    }
    
    return [NSDictionary dictionaryWithDictionary:sanitizedDictionary];
}

#pragma mark - Custom methods

- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated
{
    if ([self noBlogsAndNoWordPressDotComAccount]) {
        UIViewController *presenter = self.window.rootViewController;
        // Check if the presentedVC is UIAlertController because in iPad we show a Sign-out button in UIActionSheet
        // and it's not dismissed before the check and `dismissViewControllerAnimated` does not work for it
        if (presenter.presentedViewController && ![presenter.presentedViewController isKindOfClass:[UIAlertController class]]) {
            [presenter dismissViewControllerAnimated:animated completion:^{
                [self showWelcomeScreenAnimated:animated thenEditor:NO];
            }];
        } else {
            [self showWelcomeScreenAnimated:animated thenEditor:NO];
        }
    }
}

- (void)showWelcomeScreenAnimated:(BOOL)animated thenEditor:(BOOL)thenEditor
{
    __weak __typeof(self) weakSelf = self;
    
    LoginViewController *loginViewController = [[LoginViewController alloc] init];
    loginViewController.showEditorAfterAddingSites = thenEditor;
    loginViewController.cancellable = NO;
    loginViewController.dismissBlock = ^{
        
        __strong __typeof(weakSelf) strongSelf = self;
        
        [strongSelf.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        [strongSelf showWhatsNewIfNeeded];
    };

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    navigationController.navigationBar.translucent = NO;

    [self.window.rootViewController presentViewController:navigationController animated:animated completion:nil];
}

- (BOOL)noBlogsAndNoWordPressDotComAccount
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    NSInteger blogCount = [blogService blogCountSelfHosted];
    return blogCount == 0 && !defaultAccount;
}

- (void)customizeAppearance
{
    UIColor *defaultTintColor = self.window.tintColor;
    self.window.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    self.window.tintColor = [WPStyleGuide wordPressBlue];

    [[UINavigationBar appearance] setBarTintColor:[WPStyleGuide wordPressBlue]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    [[UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil] setTintColor:defaultTintColor];

    [[UITabBar appearance] setShadowImage:[UIImage imageWithColor:[UIColor colorWithRed:210.0/255.0 green:222.0/255.0 blue:230.0/255.0 alpha:1.0]]];
    [[UITabBar appearance] setTintColor:[WPStyleGuide newKidOnTheBlockBlue]];

    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [WPFontManager openSansBoldFontOfSize:16.0]} ];

    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageWithColor:[WPStyleGuide wordPressBlue]] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[UIImage imageWithColor:[UIColor UIColorFromHex:0x007eb1]]];

    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.25]} forState:UIControlStateDisabled];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont]} forState:UIControlStateNormal];
    [[UIToolbar appearance] setBarTintColor:[WPStyleGuide wordPressBlue]];
    [[UISwitch appearance] setOnTintColor:[WPStyleGuide wordPressBlue]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPFontManager openSansRegularFontOfSize:10.0], NSForegroundColorAttributeName: [WPStyleGuide allTAllShadeGrey]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [WPStyleGuide wordPressBlue]} forState:UIControlStateSelected];

    [[UINavigationBar appearanceWhenContainedIn:[UIReferenceLibraryViewController class], nil] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearanceWhenContainedIn:[UIReferenceLibraryViewController class], nil] setBarTintColor:[WPStyleGuide wordPressBlue]];
    [[UIToolbar appearanceWhenContainedIn:[UIReferenceLibraryViewController class], nil] setBarTintColor:[UIColor darkGrayColor]];
    
    [[UIToolbar appearanceWhenContainedIn:[WPEditorViewController class], nil] setBarTintColor:[UIColor whiteColor]];

    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[WPStyleGuide littleEddieGrey]]];
    
    // SVProgressHUD styles    
    [SVProgressHUD setBackgroundColor:[[WPStyleGuide littleEddieGrey] colorWithAlphaComponent:0.95]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
    [SVProgressHUD setFont:[WPFontManager openSansRegularFontOfSize:18.0]];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"hud_error"]];
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hud_success"]];
}

#pragma mark - App Rating

- (void)initializeAppRatingUtility
{
    // Dont start App Tracking if we are running the test suite
    if ([NSProcessInfo isRunningTests]) {
        return;
    }
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [AppRatingUtility registerSection:@"notifications" withSignificantEventCount:5];
    [AppRatingUtility setSystemWideSignificantEventsCount:10];
    [AppRatingUtility initializeForVersion:version];
    [AppRatingUtility checkIfAppReviewPromptsHaveBeenDisabled:nil failure:^{
        DDLogError(@"Was unable to retrieve data about throttling");
    }];
}

#pragma mark - Application directories

- (void)changeCurrentDirectory
{
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

#pragma mark - Crash reporting

- (void)configureCrashlytics
{
#if defined(INTERNAL_BUILD) || defined(DEBUG)
    return;
#endif

    if ([[WordPressComApiCredentials crashlyticsApiKey] length] == 0) {
        return;
    }

    [Crashlytics startWithAPIKey:[WordPressComApiCredentials crashlyticsApiKey]];
    [[Crashlytics sharedInstance] setDelegate:self];

    [self setCommonCrashlyticsParameters];
}

- (void)crashlytics:(Crashlytics *)crashlytics didDetectCrashDuringPreviousExecution:(id<CLSCrashReport>)crash
{
    DDLogMethod();
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger crashCount = [defaults integerForKey:@"crashCount"];
    crashCount += 1;
    [defaults setInteger:crashCount forKey:@"crashCount"];
    [defaults synchronize];
}

- (void)setCommonCrashlyticsParameters
{
#if defined(INTERNAL_BUILD) || defined(DEBUG)
    return;
#endif
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    BOOL loggedIn = defaultAccount != nil;
    [Crashlytics setUserName:defaultAccount.username];
    [Crashlytics setObjectValue:@(loggedIn) forKey:@"logged_in"];
    [Crashlytics setObjectValue:@(loggedIn) forKey:@"connected_to_dotcom"];
    [Crashlytics setObjectValue:@([blogService blogCountForAllAccounts]) forKey:@"number_of_blogs"];
}

- (void)configureHockeySDK
{
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

- (NSString *)applicationLogForCrashManager:(BITCrashManager *)crashManager
{
    NSString *description = [self getLogFilesContentWithMaxSize:5000]; // 5000 bytes should be enough!
    if ([description length] == 0) {
        return nil;
    }

    return description;
}

#pragma mark - Media cleanup

- (void)cleanUnusedMediaFileFromTmpDir
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    [context performBlock:^{

        // Fetch Media URL's and return them as Dictionary Results:
        // This way we'll avoid any CoreData Faulting Exception due to deletions performed on another context
        NSString *localUrlProperty      = NSStringFromSelector(@selector(localURL));

        NSFetchRequest *fetchRequest    = [[NSFetchRequest alloc] init];
        fetchRequest.entity             = [NSEntityDescription entityForName:NSStringFromClass([Media class]) inManagedObjectContext:context];
        fetchRequest.predicate          = [NSPredicate predicateWithFormat:@"ANY posts.blog != NULL AND remoteStatusNumber <> %@", @(MediaRemoteStatusSync)];

        fetchRequest.propertiesToFetch  = @[ localUrlProperty ];
        fetchRequest.resultType         = NSDictionaryResultType;

        NSError *error = nil;
        NSArray *mediaObjectsToKeep     = [context executeFetchRequest:fetchRequest error:&error];

        if (error) {
            DDLogError(@"Error cleaning up tmp files: %@", error.localizedDescription);
            return;
        }

        // Get a references to media files linked in a post
        DDLogInfo(@"%i media items to check for cleanup", mediaObjectsToKeep.count);

        NSMutableSet *pathsToKeep       = [NSMutableSet set];
        for (NSDictionary *mediaDict in mediaObjectsToKeep) {
            NSString *path = mediaDict[localUrlProperty];
            if (path) {
                [pathsToKeep addObject:path];
            }
        }

        // Search for [JPG || JPEG || PNG || GIF] files within the Documents Folder
        NSString *documentsDirectory    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSArray *contentsOfDir          = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];

        NSSet *mediaExtensions          = [NSSet setWithObjects:@"jpg", @"jpeg", @"png", @"gif", nil];

        for (NSString *currentPath in contentsOfDir) {
            NSString *extension = currentPath.pathExtension.lowercaseString;
            if (![mediaExtensions containsObject:extension]) {
                continue;
            }

            // If the file is not referenced in any post we can delete it
            NSString *filepath = [documentsDirectory stringByAppendingPathComponent:currentPath];

            if (![pathsToKeep containsObject:filepath]) {
                NSError *nukeError = nil;
                if ([[NSFileManager defaultManager] removeItemAtPath:filepath error:&nukeError] == NO) {
                    DDLogError(@"Error [%@] while nuking Unused Media at path [%@]", nukeError.localizedDescription, filepath);
                }
            }
        }
    }];
}



#pragma mark - User agents

- (void)setupUserAgent
{
    // Keep a copy of the original userAgent for use with certain webviews in the app.
    NSString *defaultUA = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSString *wordPressUserAgent = [[UIDevice currentDevice] wordPressUserAgent];

    NSDictionary *dictionary = @{
        @"UserAgent"        : wordPressUserAgent,
        @"DefaultUserAgent" : defaultUA,
        @"AppUserAgent"     : wordPressUserAgent
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}

- (void)useDefaultUserAgent
{
    NSString *ua = [[NSUserDefaults standardUserDefaults] stringForKey:@"DefaultUserAgent"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:ua, @"UserAgent", nil];
    // We have to call registerDefaults else the change isn't picked up by UIWebViews.
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    DDLogVerbose(@"User-Agent set to: %@", ua);
}

- (void)useAppUserAgent
{
    NSString *ua = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppUserAgent"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:ua, @"UserAgent", nil];
    // We have to call registerDefaults else the change isn't picked up by UIWebViews.
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    
    DDLogVerbose(@"User-Agent set to: %@", ua);
}

- (NSString *)applicationUserAgent
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
}


#pragma mark - Networking setup

- (void)setupSingleSignOn
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    WPComOAuthController *oAuthController = [WPComOAuthController sharedController];
    
    [oAuthController setWordPressComUsername:defaultAccount.username];
    [oAuthController setWordPressComAuthToken:defaultAccount.authToken];
}

- (void)setupReachability
{
    // Setup Reachability
    self.internetReachability = [Reachability reachabilityForInternetConnection];

    __weak __typeof(self) weakSelf = self;
    
    void (^internetReachabilityBlock)(Reachability *) = ^(Reachability *reach) {
        NSString *wifi = reach.isReachableViaWiFi ? @"Y" : @"N";
        NSString *wwan = reach.isReachableViaWWAN ? @"Y" : @"N";

        DDLogInfo(@"Reachability - Internet - WiFi: %@  WWAN: %@", wifi, wwan);
        weakSelf.connectionAvailable = reach.isReachable;
    };
    self.internetReachability.reachableBlock = internetReachabilityBlock;
    self.internetReachability.unreachableBlock = internetReachabilityBlock;

    // Start the Notifier
    [self.internetReachability startNotifier];
    
    self.connectionAvailable = [self.internetReachability isReachable];
}

#pragma mark - Simperium

- (void)configureSimperiumWithLaunchOptions:(NSDictionary *)launchOptions
{
	ContextManager* manager         = [ContextManager sharedInstance];
    NSString *bucketName            = [self notificationsBucketNameFromLaunchOptions:launchOptions];
    NSDictionary *bucketOverrides   = @{ NSStringFromClass([Notification class]) : bucketName };
    
    self.simperium = [[Simperium alloc] initWithModel:manager.managedObjectModel
											  context:manager.mainContext
										  coordinator:manager.persistentStoreCoordinator
                                                label:[NSString string]
                                      bucketOverrides:bucketOverrides];

    // Note: Nuke Simperium's metadata in case of a faulty Core Data migration
    if (manager.didMigrationFail) {
        [self.simperium resetMetadata];
    }

#ifdef DEBUG
	self.simperium.verboseLoggingEnabled = false;
#endif
}

- (void)loginSimperium
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *account              = [accountService defaultWordPressComAccount];
    NSString *apiKey                = [WordPressComApiCredentials simperiumAPIKey];

    if (!account.authToken.length || !apiKey.length) {
        return;
    }

    NSString *simperiumToken = [NSString stringWithFormat:@"WPCC/%@/%@", apiKey, account.authToken];
    NSString *simperiumAppID = [WordPressComApiCredentials simperiumAppId];
    [self.simperium authenticateWithAppID:simperiumAppID token:simperiumToken];
}

- (void)logoutSimperiumAndResetNotifications
{
    [self.simperium signOutAndRemoveLocalData:YES completion:nil];
}

- (NSString *)notificationsBucketNameFromLaunchOptions:(NSDictionary *)launchOptions
{
    NSURL *launchURL = launchOptions[UIApplicationLaunchOptionsURLKey];
    NSString *name = nil;
    
    if ([launchURL.host isEqualToString:@"notifications"]) {
        name = [[launchURL.query dictionaryFromQueryString] stringForKey:@"bucket_name"];
    }
    
    return name ?: WPNotificationsBucketName;
}


#pragma mark - Keychain

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

#pragma mark - WordPress.com Accounts

- (void)removeWordPressComPassword
{
    // Nuke WordPress.com stored passwords, since it's no longer required.
    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:mainContext];
    [accountService removeWordPressComAccountPasswordIfNeeded];
}


#pragma mark - Debugging and logging

- (void)printDebugLaunchInfoWithLaunchOptions:(NSDictionary *)launchOptions
{
    UIDevice *device = [UIDevice currentDevice];
    NSInteger crashCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"crashCount"];
    NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    NSString *currentLanguage = [languages objectAtIndex:0];
    BOOL extraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    NSArray *blogs = [blogService blogsForAllAccounts];

    DDLogInfo(@"===========================================================================");
    DDLogInfo(@"Launching WordPress for iOS %@...", [[NSBundle mainBundle] detailedVersionNumber]);
    DDLogInfo(@"Crash count:       %d", crashCount);
#ifdef DEBUG
    DDLogInfo(@"Debug mode:  Debug");
#else
    DDLogInfo(@"Debug mode:  Production");
#endif
    DDLogInfo(@"Extra debug: %@", extraDebug ? @"YES" : @"NO");
    DDLogInfo(@"Device model: %@ (%@)", [UIDeviceHardware platformString], [UIDeviceHardware platform]);
    DDLogInfo(@"OS:        %@ %@", device.systemName, device.systemVersion);
    DDLogInfo(@"Language:  %@", currentLanguage);
    DDLogInfo(@"UDID:      %@", device.wordPressIdentifier);
    DDLogInfo(@"APN token: %@", [NotificationsManager registeredPushNotificationsToken]);
    DDLogInfo(@"Launch options: %@", launchOptions);

    if (blogs.count > 0) {
        DDLogInfo(@"All blogs on device:");
        for (Blog *blog in blogs) {
            DDLogInfo(@"Name: %@ URL: %@ XML-RPC: %@ isWpCom: %@ blogId: %@ jetpackAccount: %@", blog.blogName, blog.url, blog.xmlrpc, blog.account.isWpcom ? @"YES" : @"NO", blog.blogID, !!blog.jetpackAccount ? @"PRESENT" : @"NONE");
        }
    } else {
        DDLogInfo(@"No blogs configured on device.");
    }

    DDLogInfo(@"===========================================================================");
}

- (void)removeCredentialsForDebug
{
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

    [DDLog addLogger:self.fileLogger];

    BOOL extraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"];
    if (extraDebug) {
        ddLogLevel = LOG_LEVEL_VERBOSE;
    }
}

- (DDFileLogger *)fileLogger
{
    if (_fileLogger) {
        return _fileLogger;
    }
    _fileLogger = [[DDFileLogger alloc] init];
    _fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    _fileLogger.logFileManager.maximumNumberOfLogFiles = 7;

    return _fileLogger;
}

// get the log content with a maximum byte size
- (NSString *)getLogFilesContentWithMaxSize:(NSInteger)maxSize
{
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
        description = (NSMutableString *)[description substringWithRange:NSMakeRange(0, maxSize)];
    }

    return description;
}

- (void)toggleExtraDebuggingIfNeeded
{
    if ([self noBlogsAndNoWordPressDotComAccount]) {
        // When there are no blogs in the app the settings screen is unavailable.
        // In this case, enable extra_debugging by default to help troubleshoot any issues.
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"orig_extra_debug"] != nil) {
            return; // Already saved. Don't save again or we could loose the original value.
        }

        NSString *origExtraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"] ? @"YES" : @"NO";
        [[NSUserDefaults standardUserDefaults] setObject:origExtraDebug forKey:@"orig_extra_debug"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"extra_debug"];
        ddLogLevel = LOG_LEVEL_VERBOSE;
        [NSUserDefaults resetStandardUserDefaults];
    } else {
        NSString *origExtraDebug = [[NSUserDefaults standardUserDefaults] stringForKey:@"orig_extra_debug"];
        if (origExtraDebug == nil) {
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

#pragma mark - Local Notifications Helpers

- (void)listenLocalNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleDefaultAccountChangedNote:)
                               name:WPAccountDefaultWordPressComAccountChangedNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleLowMemoryWarningNote:)
                               name:UIApplicationDidReceiveMemoryWarningNotification
                             object:nil];
}

- (void)handleDefaultAccountChangedNote:(NSNotification *)notification
{
    // If the notification object is not nil, then it's a login
    if (notification.object) {
        [self loginSimperium];

        NSManagedObjectContext *context     = [[ContextManager sharedInstance] newDerivedContext];
        ReaderTopicService *topicService    = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
        [context performBlock:^{
            ReaderTopic *topic              = topicService.currentTopic;
            if (topic) {
                ReaderPostService *service  = [[ReaderPostService alloc] initWithManagedObjectContext:context];
                [service fetchPostsForTopic:topic success:nil failure:nil];
            }
        }];
    } else {
        if ([self noBlogsAndNoWordPressDotComAccount]) {
            [WPAnalytics track:WPAnalyticsStatLogout];
        }
        [self logoutSimperiumAndResetNotifications];
        [self showWelcomeScreenIfNeededAnimated:NO];
        [self removeTodayWidgetConfiguration];
    }
    
    [self toggleExtraDebuggingIfNeeded];
    [self setCommonCrashlyticsParameters];
    [self setupSingleSignOn];
    
    [WPAnalytics track:WPAnalyticsStatDefaultAccountChanged];
}

- (void)handleLowMemoryWarningNote:(NSNotification *)notification
{
    [WPAnalytics track:WPAnalyticsStatLowMemoryWarning];
}


#pragma mark - Today Extension

- (void)determineIfTodayWidgetIsConfiguredAndShowAppropriately
{
    TodayExtensionService *service = [TodayExtensionService new];
    [service hideTodayWidgetIfNotConfigured];
}

- (void)removeTodayWidgetConfiguration
{
    TodayExtensionService *service = [TodayExtensionService new];
    [service removeTodayWidgetConfiguration];
}

#pragma mark - What's new

/**
 *  @brief      Shows the What's New popup if needed.
 *  @details    Takes care of saving the user defaults that signal that What's New was already
 *              shown.  Also adds a slight delay before showing anything.  Also does nothing if
 *              the user is not logged in.
 */
- (void)showWhatsNewIfNeeded
{
    if (!self.wasWhatsNewShown) {
        BOOL userIsLoggedIn = ![self noBlogsAndNoWordPressDotComAccount];
        
        if (userIsLoggedIn) {
            if ([self mustShowWhatsNewPopup]) {
                
                static NSString* const WhatsNewUserDefaultsKey = @"WhatsNewUserDefaultsKey";
                static const CGFloat WhatsNewShowDelay = 1.0f;
                
                NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                
                BOOL whatsNewAlreadyShown = [userDefaults boolForKey:WhatsNewUserDefaultsKey];
                
                if (!whatsNewAlreadyShown) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(WhatsNewShowDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.wasWhatsNewShown = YES;
                        
                        WPWhatsNew* whatsNew = [[WPWhatsNew alloc] init];
                        
                        [whatsNew showWithDismissBlock:^{
                            [userDefaults setBool:YES forKey:WhatsNewUserDefaultsKey];
                        }];
                    });
                }
            }
        }
    }
}

- (BOOL)mustShowWhatsNewPopup
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:MustShowWhatsNewPopup];
}

- (void)setMustShowWhatsNewPopup:(BOOL)mustShow
{
    [[NSUserDefaults standardUserDefaults] setBool:mustShow forKey:MustShowWhatsNewPopup];
}

@end
