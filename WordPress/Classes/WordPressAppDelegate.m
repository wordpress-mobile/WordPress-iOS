#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <Crashlytics/Crashlytics.h>
#import <CrashlyticsLumberjack/CrashlyticsLogger.h>
#import <DDFileLogger.h>
#import <GooglePlus/GooglePlus.h>
#import <HockeySDK/HockeySDK.h>
#import <UIDeviceIdentifier/UIDeviceHardware.h>

#import "WordPressAppDelegate.h"
#import "ContextManager.h"
#import "Media.h"
#import "NotificationsManager.h"
#import "NSString+Helpers.h"
#import "PocketAPI.h"
#import "ReaderPost.h"
#import "UIDevice+WordPressIdentifier.h"
#import "WordPressComApiCredentials.h"
#import "WPAccount.h"
#import "AccountService.h"

#import "BlogListViewController.h"
#import "BlogDetailsViewController.h"
#import "PostsViewController.h"
#import "EditPostViewController.h"
#import "LoginViewController.h"
#import "NotificationsViewController.h"
#import "ReaderPostsViewController.h"
#import "SupportViewController.h"
#import "StatsViewController.h"
#import "Constants.h"

#if DEBUG
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#endif

int ddLogLevel = LOG_LEVEL_INFO;
static NSString * const WPTabBarRestorationID = @"WPTabBarID";
static NSString * const WPBlogListNavigationRestorationID = @"WPBlogListNavigationID";
static NSString * const WPReaderNavigationRestorationID = @"WPReaderNavigationID";
static NSString * const WPNotificationsNavigationRestorationID = @"WPNotificationsNavigationID";
static NSInteger const IndexForMeTab = 2;

@interface WordPressAppDelegate () <UITabBarControllerDelegate, CrashlyticsDelegate, UIAlertViewDelegate, BITHockeyManagerDelegate>

@property (nonatomic, assign) BOOL listeningForBlogChanges;
@property (nonatomic, strong) NotificationsViewController *notificationsViewController;
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTask;
@property (strong, nonatomic) DDFileLogger *fileLogger;

@end

@implementation WordPressAppDelegate

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate {
    return (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [WordPressAppDelegate fixKeychainAccess];

    // Crash reporting, logging, debugging
    [self configureLogging];
    [self configureHockeySDK];
    [self configureCrashlytics];
    [self printDebugLaunchInfoWithLaunchOptions:launchOptions];
    [self toggleExtraDebuggingIfNeeded];
    [self removeCredentialsForDebug];

    // Stats and feedback
    [WPMobileStats initializeStats];
    [[GPPSignIn sharedInstance] setClientID:[WordPressComApiCredentials googlePlusClientId]];
    [SupportViewController checkIfFeedbackShouldBeEnabled];
    
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
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    [self.window setFrame:bounds];
    [self.window setBounds:bounds]; // for good measure.
    self.window.backgroundColor = [UIColor blackColor];
    self.window.rootViewController = self.tabBarController;
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    DDLogVerbose(@"didFinishLaunchingWithOptions state: %d", application.applicationState);
    
    // Launched by tapping a notification
    if (application.applicationState == UIApplicationStateActive) {
        [NotificationsManager handleNotificationForApplicationLaunch:launchOptions];
    }

    [self.window makeKeyAndVisible];
    
    [self showWelcomeScreenIfNeededAnimated:NO];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
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

    if (url && [url isKindOfClass:[NSURL class]] && [[url absoluteString] hasPrefix:@"wordpress://"]) {
        NSString *URLString = [url absoluteString];
        DDLogInfo(@"Application launched with URL: %@", URLString);

        if ([URLString rangeOfString:@"newpost"].length) {
            // Create a new post from data shared by a third party application.
            NSDictionary *params = [[url query] dictionaryFromQueryString];
            DDLogInfo(@"App launched for new post with params: %@", params);
            if ([params count]) {
                [self showPostTabWithOptions:params];
                returnValue = YES;
            }
        } else if ([URLString rangeOfString:@"viewpost"].length) {
            // View the post specified by the shared blog ID and post ID
            NSDictionary *params = [[url query] dictionaryFromQueryString];
            
            if (params.count) {
                NSUInteger blogId = [[params numberForKey:@"blogId"] integerValue];
                NSUInteger postId = [[params numberForKey:@"postId"] integerValue];
                
                [WPMobileStats flagSuperProperty:StatsPropertyReaderOpenedFromExternalURL];
                [WPMobileStats incrementSuperProperty:StatsPropertyReaderOpenedFromExternalURLCount];
                [WPMobileStats trackEventForWPCom:StatsEventReaderOpenedFromExternalSource];
                
                [self.readerPostsViewController.navigationController popToRootViewControllerAnimated:NO];
                NSInteger readerTabIndex = [[self.tabBarController viewControllers] indexOfObject:self.readerPostsViewController.navigationController];
                [self.tabBarController setSelectedIndex:readerTabIndex];
                [self.readerPostsViewController openPost:postId onBlog:blogId];
                
                returnValue = YES;
            }
        }
    }

    return returnValue;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
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

- (void)applicationWillEnterForeground:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
}

- (void)applicationWillResignActive:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    
    [WPMobileStats recordAppOpenedForEvent:StatsEventAppOpened];
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
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
    DDLogMethod();
    
    [NotificationsManager handleNotification:userInfo forState:application.applicationState completionHandler:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    DDLogMethod();
    
    [NotificationsManager handleNotification:userInfo forState:[UIApplication sharedApplication].applicationState completionHandler:completionHandler];
}

#pragma mark - Custom methods

- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated {
    if ([self noBlogsAndNoWordPressDotComAccount]) {
        UIViewController *presenter = self.window.rootViewController;
        if (presenter.presentedViewController) {
            [presenter dismissViewControllerAnimated:NO completion:nil];
        }

        [self showWelcomeScreenAnimated:animated thenEditor:NO];
    }
}

- (void)showWelcomeScreenAnimated:(BOOL)animated thenEditor:(BOOL)thenEditor {
    LoginViewController *loginViewController = [[LoginViewController alloc] init];
    if (thenEditor) {
        loginViewController.dismissBlock = ^{
            [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        };
        loginViewController.showEditorAfterAddingSites = YES;
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    navigationController.navigationBar.translucent = NO;

    [self.window.rootViewController presentViewController:navigationController animated:animated completion:nil];
}

- (BOOL)noBlogsAndNoWordPressDotComAccount {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    NSInteger blogCount = [Blog countSelfHostedWithContext:context];
    return blogCount == 0 && !defaultAccount;
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
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"OpenSans" size:10.0]} forState:UIControlStateNormal];

    [[UINavigationBar appearanceWhenContainedIn:[UIReferenceLibraryViewController class], nil] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearanceWhenContainedIn:[UIReferenceLibraryViewController class], nil] setBarTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
    [[UIToolbar appearanceWhenContainedIn:[UIReferenceLibraryViewController class], nil] setBarTintColor:[UIColor darkGrayColor]];
}

#pragma mark - Tab bar methods

- (UITabBarController *)tabBarController {
    if (_tabBarController) {
        return _tabBarController;
    }
    
    UIOffset tabBarTitleOffset = UIOffsetMake(0, 0);
    if ( IS_IPHONE ) {
        tabBarTitleOffset = UIOffsetMake(0, -2);
    }
    _tabBarController = [[UITabBarController alloc] init];
    _tabBarController.delegate = self;
    _tabBarController.restorationIdentifier = WPTabBarRestorationID;
    [_tabBarController.tabBar setTranslucent:NO];


    // Create a background
    // (not strictly needed when white, but left here for possible customization)
    UIColor *backgroundColor = [UIColor whiteColor];
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
    CGContextFillRect(context, rect);
    UIImage *tabBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _tabBarController.tabBar.backgroundImage = tabBackgroundImage;
    
    self.readerPostsViewController = [[ReaderPostsViewController alloc] init];
    UINavigationController *readerNavigationController = [[UINavigationController alloc] initWithRootViewController:self.readerPostsViewController];
    readerNavigationController.navigationBar.translucent = NO;
    readerNavigationController.tabBarItem.image = [UIImage imageNamed:@"icon-tab-reader"];
    readerNavigationController.tabBarItem.selectedImage = [UIImage imageNamed:@"icon-tab-reader-filled"];
    readerNavigationController.restorationIdentifier = WPReaderNavigationRestorationID;
    self.readerPostsViewController.title = NSLocalizedString(@"Reader", nil);
    [readerNavigationController.tabBarItem setTitlePositionAdjustment:tabBarTitleOffset];
    
    self.notificationsViewController = [[NotificationsViewController alloc] init];
    UINavigationController *notificationsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.notificationsViewController];
    notificationsNavigationController.navigationBar.translucent = NO;
    notificationsNavigationController.tabBarItem.image = [UIImage imageNamed:@"icon-tab-notifications"];
    notificationsNavigationController.tabBarItem.selectedImage = [UIImage imageNamed:@"icon-tab-notifications-filled"];
    notificationsNavigationController.restorationIdentifier = WPNotificationsNavigationRestorationID;
    self.notificationsViewController.title = NSLocalizedString(@"Notifications", @"");
    [notificationsNavigationController.tabBarItem setTitlePositionAdjustment:tabBarTitleOffset];
    
    self.blogListViewController = [[BlogListViewController alloc] init];
    UINavigationController *blogListNavigationController = [[UINavigationController alloc] initWithRootViewController:self.blogListViewController];
    blogListNavigationController.navigationBar.translucent = NO;
    blogListNavigationController.tabBarItem.image = [UIImage imageNamed:@"icon-tab-blogs"];
    blogListNavigationController.tabBarItem.selectedImage = [UIImage imageNamed:@"icon-tab-blogs-filled"];
    blogListNavigationController.restorationIdentifier = WPBlogListNavigationRestorationID;
    self.blogListViewController.title = NSLocalizedString(@"Me", @"");
    [blogListNavigationController.tabBarItem setTitlePositionAdjustment:tabBarTitleOffset];
  
    UIImage *image = [UIImage imageNamed:@"icon-tab-newpost"];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIViewController *postsViewController = [[UIViewController alloc] init];
    postsViewController.tabBarItem.image = image;
    postsViewController.tabBarItem.imageInsets = UIEdgeInsetsMake(5.0, 0, -5, 0);
    if (IS_IPAD) {
        postsViewController.tabBarItem.imageInsets = UIEdgeInsetsMake(7.0, 0, -7, 0);
    }

    /*
     If title is used, the title will be visible. See #1158
     If accessibilityLabel/Value are used, the "New Post" text is not read by VoiceOver

     The only apparent solution is to have an actual title, and then hide it for
     non-VoiceOver users.
     */
    postsViewController.title = NSLocalizedString(@"New Post", @"The accessibility value of the post tab.");
    [postsViewController.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]} forState:UIControlStateNormal];

    _tabBarController.viewControllers = @[readerNavigationController, notificationsNavigationController, blogListNavigationController, postsViewController];

    [_tabBarController setSelectedViewController:readerNavigationController];
    
    return _tabBarController;
}

- (void)showNotificationsTab {
    NSInteger notificationsTabIndex = [[self.tabBarController viewControllers] indexOfObject:self.notificationsViewController.navigationController];
    [self.tabBarController setSelectedIndex:notificationsTabIndex];
}

- (void)showReaderTab {
    NSInteger readerTabIndex = [[self.tabBarController viewControllers] indexOfObject:self.readerPostsViewController.navigationController];
    [self.tabBarController setSelectedIndex:readerTabIndex];
}

- (void)showBlogListTab {
    NSInteger blogListTabIndex = [[self.tabBarController viewControllers] indexOfObject:self.blogListViewController.navigationController];
    [self.tabBarController setSelectedIndex:blogListTabIndex];
}

- (void)showMeTab {
    [self.tabBarController setSelectedIndex:IndexForMeTab];
}

- (void)showPostTab {
    [self showPostTabWithOptions:nil];
}

- (void)showPostTabWithOptions:(NSDictionary *)options {
    UIViewController *presenter = self.window.rootViewController;
    if (presenter.presentedViewController) {
        [presenter dismissViewControllerAnimated:NO completion:nil];
    }
    
    EditPostViewController *editPostViewController;
    if (!options) {
        [WPStats track:WPStatEditorCreatedPost];
        editPostViewController = [[EditPostViewController alloc] initWithDraftForLastUsedBlog];
    } else {
        editPostViewController = [[EditPostViewController alloc] initWithTitle:[options stringForKey:@"title"]
                                                                    andContent:[options stringForKey:@"content"]
                                                                       andTags:[options stringForKey:@"tags"]
                                                                      andImage:[options stringForKey:@"image"]];
    }
    editPostViewController.editorOpenedBy = StatsPropertyPostDetailEditorOpenedOpenedByTabBarButton;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    navController.navigationBar.translucent = NO;
    navController.restorationIdentifier = WPEditorNavigationRestorationID;
    navController.restorationClass = [EditPostViewController class];
    [navController setToolbarHidden:NO]; // Make the toolbar visible here to avoid a weird left/right transition when the VC appears.
    [self.window.rootViewController presentViewController:navController animated:YES completion:nil];
}

- (void)switchTabToPostsListForPost:(AbstractPost *)post {
    // Make sure the desired tab is selected.
    [self showMeTab];

    // Check which VC is showing.
    UINavigationController *blogListNavController = [self.tabBarController.viewControllers objectAtIndex:IndexForMeTab];
    UIViewController *topVC = blogListNavController.topViewController;
    if ([topVC isKindOfClass:[PostsViewController class]]) {
        Blog *blog = ((PostsViewController *)topVC).blog;
        if ([post.blog.objectID isEqual:blog.objectID]) {
            // The desired post view controller is already the top viewController for the tab.
            // Nothing to see here.  Move along.
            return;
        }
    }
    
    // Build and set the navigation heirarchy for the Me tab.
    BlogListViewController *blogListViewController = [blogListNavController.viewControllers objectAtIndex:0];
    
    BlogDetailsViewController *blogDetailsViewController = [[BlogDetailsViewController alloc] init];
    blogDetailsViewController.blog = post.blog;

    PostsViewController *postsViewController = [[PostsViewController alloc] init];
    [postsViewController setBlog:post.blog];
    
    [blogListNavController setViewControllers:@[blogListViewController, blogDetailsViewController, postsViewController]];
}

- (void)showStatsForBlog:(Blog *)blog {
    UINavigationController *blogListNav = self.tabBarController.viewControllers[IndexForMeTab];
    StatsViewController *statsViewController;
    BlogDetailsViewController *blogDetailsViewController;
    
    if ([blogListNav.topViewController isKindOfClass:[StatsViewController class]] &&
        [[(StatsViewController *)blogListNav.topViewController blog] isEqual:blog]) {
        // If we're already showing stats for the blog, just go there
        [self showMeTab];
        return;
    } else {
        statsViewController = [[StatsViewController alloc] init];
        statsViewController.blog = blog;
    }
    
    if ([blogListNav.topViewController isKindOfClass:[BlogDetailsViewController class]] &&
        [((BlogDetailsViewController *)blogListNav.topViewController).blog isEqual:blog]) {
        // Use the current blog details view controller
        blogDetailsViewController = (BlogDetailsViewController *)blogListNav.topViewController;
    } else {
        blogDetailsViewController = [[BlogDetailsViewController alloc] init];
        blogDetailsViewController.blog = blog;
    }
    
    blogListNav.viewControllers = @[self.blogListViewController, blogDetailsViewController, statsViewController];
    [self showMeTab];
}

- (BOOL)isNavigatingMeTab {
    return (self.tabBarController.selectedIndex == IndexForMeTab && [self.blogListViewController.navigationController.viewControllers count] > 1);
}

#pragma mark - UITabBarControllerDelegate methods.

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([tabBarController.viewControllers indexOfObject:viewController] == 3) {
        // Ignore taps on the post tab and instead show the modal.
        if ([Blog countVisibleWithContext:[[ContextManager sharedInstance] mainContext]] == 0) {
            [WPMobileStats trackEventForWPCom:StatsEventAccountCreationOpenedFromTabBar];
            [self showWelcomeScreenAnimated:YES thenEditor:YES];
        } else {
            [self showPostTab];
        }
        return NO;
    } else if ([tabBarController.viewControllers indexOfObject:viewController] == 2) {
        // If the user has one blog then we don't want to present them with the main "me"
        // screen where they can see all their blogs. In the case of only one blog just show
        // the main blog details screen

        // Don't kick of this auto selecting behavior if the user taps the the active tab as it
        // would break from standard iOS UX
        if (tabBarController.selectedIndex != 2) {
            UINavigationController *navController = (UINavigationController *)viewController;
            BlogListViewController *blogListViewController = (BlogListViewController *)navController.viewControllers[0];
            if ([blogListViewController shouldBypassBlogListViewControllerWhenSelectedFromTabBar]) {
                if ([navController.visibleViewController isKindOfClass:[blogListViewController class]]) {
                    [blogListViewController bypassBlogListViewController];
                }
            }
        }
    }
    return YES;
}


#pragma mark - Application directories

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


#pragma mark - Notifications

- (void)defaultAccountDidChange:(NSNotification *)notification {
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    [Crashlytics setUserName:[defaultAccount username]];
    [self setCommonCrashlyticsParameters];
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
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    BOOL hasCredentials = (defaultAccount != nil);
    [self setCommonCrashlyticsParameters];
    
    if (hasCredentials && [defaultAccount username] != nil) {
        [Crashlytics setUserName:[defaultAccount username]];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultAccountDidChange:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
}

- (void)crashlytics:(Crashlytics *)crashlytics didDetectCrashDuringPreviousExecution:(id<CLSCrashReport>)crash
{
    DDLogMethod();
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger crashCount = [defaults integerForKey:@"crashCount"];
    crashCount += 1;
    [defaults setInteger:crashCount forKey:@"crashCount"];
    [defaults synchronize];
    [WPMobileStats trackEventForSelfHostedAndWPCom:@"Crashed" properties:@{@"crash_id": crash.identifier}];
}

- (void)setCommonCrashlyticsParameters
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    BOOL loggedIn = defaultAccount != nil;
    [Crashlytics setObjectValue:@(loggedIn) forKey:@"logged_in"];
    [Crashlytics setObjectValue:@(loggedIn) forKey:@"connected_to_dotcom"];
    [Crashlytics setObjectValue:@([Blog countWithContext:context]) forKey:@"number_of_blogs"];
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
            if (media.localURL) {
                [mediaToKeep addObject:media.localURL];
            }
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
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    if ([defaultAccount username]) {
        [[WPComOAuthController sharedController] setWordPressComUsername:[defaultAccount username]];
        [[WPComOAuthController sharedController] setWordPressComPassword:[defaultAccount password]];
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
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    
    // set the blocks
    void (^internetReachabilityBlock)(Reachability *) = ^(Reachability *reach) {
        NSString *wifi = reach.isReachableViaWiFi ? @"Y" : @"N";
        NSString *wwan = reach.isReachableViaWWAN ? @"Y" : @"N";
        
        DDLogInfo(@"Reachability - Internet - WiFi: %@  WWAN: %@", wifi, wwan);
        self.connectionAvailable = reach.isReachable;
    };
    self.internetReachability.reachableBlock = internetReachabilityBlock;
    self.internetReachability.unreachableBlock = internetReachabilityBlock;
    
    // start the notifier which will cause the reachability object to retain itself!
    [self.internetReachability startNotifier];
    self.connectionAvailable = [self.internetReachability isReachable];
    
    // allocate the WP.com reachability object
    self.wpcomReachability = [Reachability reachabilityWithHostname:@"wordpress.com"];

    // set the blocks
    void (^wpcomReachabilityBlock)(Reachability *) = ^(Reachability *reach) {
        NSString *wifi = reach.isReachableViaWiFi ? @"Y" : @"N";
        NSString *wwan = reach.isReachableViaWWAN ? @"Y" : @"N";
        CTTelephonyNetworkInfo *netInfo = [CTTelephonyNetworkInfo new];
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        NSString *type = nil;
        if ([netInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) {
            type = [netInfo currentRadioAccessTechnology];
        }
        NSString *carrierName = nil;
        if (carrier) {
            carrierName = [NSString stringWithFormat:@"%@ [%@/%@/%@]", carrier.carrierName, [carrier.isoCountryCode uppercaseString], carrier.mobileCountryCode, carrier.mobileNetworkCode];
        }
        
        DDLogInfo(@"Reachability - WordPress.com - WiFi: %@  WWAN: %@  Carrier: %@  Type: %@", wifi, wwan, carrierName, type);
        self.wpcomAvailable = reach.isReachable;
    };
    self.wpcomReachability.reachableBlock = wpcomReachabilityBlock;
    self.wpcomReachability.unreachableBlock = wpcomReachabilityBlock;

    // start the notifier which will cause the reachability object to retain itself!
    [self.wpcomReachability startNotifier];
#pragma clang diagnostic pop
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


#pragma mark - Debugging and logging

- (void)printDebugLaunchInfoWithLaunchOptions:(NSDictionary *)launchOptions {
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
    DDLogInfo(@"APN token: %@", [[NSUserDefaults standardUserDefaults] objectForKey:NotificationsDeviceToken]);
    DDLogInfo(@"Launch options: %@", launchOptions);
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
    
    [DDLog addLogger:self.fileLogger];
    
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
        description = (NSMutableString *)[description substringWithRange:NSMakeRange(0, maxSize)];
    }
    
    return description;
}

- (void)toggleExtraDebuggingIfNeeded {
    if (!_listeningForBlogChanges) {
        _listeningForBlogChanges = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDefaultAccountChangedNotification:) name:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
    }
    
	if ([self noBlogsAndNoWordPressDotComAccount]) {
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

- (void)handleDefaultAccountChangedNotification:(NSNotification *)notification {
	[self toggleExtraDebuggingIfNeeded];

    // If the notification object is not nil, then it's a login
    if (notification.object) {
        [ReaderPost fetchPostsWithCompletionHandler:nil];
    } else {
        // No need to check for welcome screen unless we are signing out
        [self showWelcomeScreenIfNeededAnimated:NO];
    }
}

@end
