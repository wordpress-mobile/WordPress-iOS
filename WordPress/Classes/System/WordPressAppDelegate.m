#import "WordPressAppDelegate.h"

// Constants
#import "Constants.h"

// Pods
#import <Crashlytics/Crashlytics.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <WordPressUI/WordPressUI.h>

#ifdef BUDDYBUILD_ENABLED
#import <BuddyBuildSDK/BuddyBuildSDK.h>
#endif

// Data model
#import "Blog.h"

// Data services
#import "BlogService.h"
#import "MediaService.h"

// Logging
#import "WPLogger.h"
#import <AutomatticTracks/TracksLogging.h>
#import <WordPressComStatsiOS/WPStatsLogging.h>
#import <WordPressAuthenticator/WPAuthenticatorLogging.h>

// Misc managers, helpers, utilities
#import "ContextManager.h"
#import "TodayExtensionService.h"
#import "WPAuthTokenIssueSolver.h"
#import <ZendeskSDK/ZendeskSDK.h>

// Networking
#import "WPUserAgent.h"
#import "ApiCredentials.h"

// Swift support
#import "WordPress-Swift.h"

// View controllers
#import "StatsViewController.h"
#import "WPTabBarController.h"
#import <WPMediaPicker/WPMediaPicker.h>

DDLogLevel ddLogLevel = DDLogLevelInfo;

@interface WordPressAppDelegate () <UITabBarControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong, readwrite) WPLogger                       *logger;
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier     bgTask;
@property (nonatomic, assign, readwrite) BOOL                           shouldRestoreApplicationState;
@property (nonatomic, strong, readwrite) PingHubManager                 *pinghubManager;
@property (nonatomic, strong, readwrite) WP3DTouchShortcutCreator       *shortcutCreator;
@property (nonatomic, strong, readwrite) NoticePresenter                *noticePresenter;

@end

@implementation WordPressAppDelegate

+ (WordPressAppDelegate *)sharedInstance
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
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [WordPressAppDelegate fixKeychainAccess];

    // Authentication Framework
    [self configureWordPressAuthenticator];

    // Basic networking setup
    [self configureReachability];
    [self configureSelfHostedChallengeHandler];

    // Set the main window up
    [self.window makeKeyAndVisible];

    // Local Notifications
    [self addNotificationObservers];

    WPAuthTokenIssueSolver *authTokenIssueSolver = [[WPAuthTokenIssueSolver alloc] init];
    
    __weak __typeof(self) weakSelf = self;

    BOOL isFixingAuthTokenIssue = [authTokenIssueSolver fixAuthTokenIssueAndDo:^{
        [weakSelf runStartupSequenceWithLaunchOptions:launchOptions];
    }];

    self.shouldRestoreApplicationState = !isFixingAuthTokenIssue;

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    DDLogVerbose(@"didFinishLaunchingWithOptions state: %d", application.applicationState);

    [[InteractiveNotificationsManager shared] registerForUserNotifications];
    [self showWelcomeScreenIfNeededAnimated:NO];
    [self setupBuddyBuild];
    [self setupPingHub];
    [self setupShortcutCreator];
    [self setupBackgroundRefresh:application];
    [self setupComponentsAppearance];
    [self disableAnimationsForUITests:application];

    return YES;
}

- (void)setupBuddyBuild
{
#ifdef BUDDYBUILD_ENABLED
    [BuddyBuildSDK setScreenshotAllowedCallback:^BOOL{
        return NO;
    }];
    
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    NSString *username = defaultAccount.username;
    
    if (username.length > 0) {
        [BuddyBuildSDK setUserDisplayNameCallback:^() {
            return @"Johnny Appleseed";
        }];
    }
    
    [BuddyBuildSDK setup];
#endif
}

- (void)setupPingHub
{
    self.pinghubManager = [PingHubManager new];
}

- (void)setupShortcutCreator
{
    self.shortcutCreator = [WP3DTouchShortcutCreator new];
}

/**
 This method will disable animations and speed-up keyboad input if command-line arguments includes "NoAnimations"
 It was designed to be used in UI test suites. To enable it just pass a launch argument into XCUIApplicaton:

 XCUIApplication().launchArguments = ["NoAnimations"]
*/
- (void)disableAnimationsForUITests:(UIApplication *)application {
    NSArray *args = [NSProcessInfo processInfo].arguments;
    
    for (NSString *arg in args){
        if ([arg isEqualToString:@"NoAnimations"]){
            [UIView setAnimationsEnabled:false];
            application.windows.firstObject.layer.speed = MAXFLOAT;
            application.keyWindow.layer.speed = MAXFLOAT;
        }
    }}

- (void)setupBackgroundRefresh:(UIApplication *)application {
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
}

- (void)configureNoticePresenter
{
    self.noticePresenter = [[NoticePresenter alloc] initWithPresentingViewController:self.window.rootViewController];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    DDLogInfo(@"Application launched with URL: %@", url);
    BOOL returnValue = NO;

    if ([self.hockey handleOpenURL:url options:options]) {
        returnValue = YES;
    }

    if ([WordPressAuthenticator.shared handleGoogleAuthUrl:url sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey] annotation:options[UIApplicationOpenURLOptionsAnnotationKey]]) {
        returnValue = YES;
    }

    if ([url isKindOfClass:[NSURL class]] && [[url absoluteString] hasPrefix:WPComScheme]) {
        NSString *URLString = [url absoluteString];

        if ([URLString rangeOfString:@"magic-login"].length) {
            DDLogInfo(@"App launched with authentication link");
            BOOL allowWordPressComAuth = [AccountHelper isDotcomAvailable] == false;
            returnValue = [WordPressAuthenticator openAuthenticationURL:url allowWordPressComAuth:allowWordPressComAuth fromRootViewController:self.window.rootViewController];
        } else if ([URLString rangeOfString:@"viewpost"].length) {
            // View the post specified by the shared blog ID and post ID
            NSDictionary *params = [[url query] dictionaryFromQueryString];
            
            if (params.count) {
                NSNumber *blogId = [params numberForKey:@"blogId"];
                NSNumber *postId = [params numberForKey:@"postId"];

                WPTabBarController *tabBarController = [WPTabBarController sharedInstance];
                [tabBarController showReaderTabForPost:postId onBlog:blogId];

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

                if ([[ApiCredentials debuggingKey] isEqualToString:@""] || [debugKey isEqualToString:@""]) {
                    return NO;
                }

                if ([debugKey isEqualToString:[ApiCredentials debuggingKey]]) {
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
            if (self.bgTask != UIBackgroundTaskInvalid) {
                [app endBackgroundTask:self.bgTask];
                self.bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
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
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    NSUserDefaults* standardUserDefaults = [NSUserDefaults standardUserDefaults];

    NSString* const lastSavedStateVersionKey = @"lastSavedStateVersionKey";
    NSString* lastSavedStateVersion = [standardUserDefaults objectForKey:lastSavedStateVersionKey];
    NSString* currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    BOOL shouldRestoreApplicationState = NO;

    if (lastSavedStateVersion && [lastSavedStateVersion length] > 0 && [lastSavedStateVersion isEqualToString:currentVersion]) {
        shouldRestoreApplicationState = self.shouldRestoreApplicationState;;
    }

    [standardUserDefaults setObject:currentVersion forKey:lastSavedStateVersionKey];

    return shouldRestoreApplicationState;
}

- (void)application: (UIApplication *)application performActionForShortcutItem:(nonnull UIApplicationShortcutItem *)shortcutItem completionHandler:(nonnull void (^)(BOOL))completionHandler
{
    WP3DTouchShortcutHandler *shortcutHandler = [[WP3DTouchShortcutHandler alloc] init];
    completionHandler([shortcutHandler handleShortcutItem:shortcutItem]);
}

- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSString *restoreID = [identifierComponents lastObject];
    return [[Restorer new] viewControllerWithIdentifier:restoreID];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {

    // 21-Oct-2017: We are only handling background URLSessions initiated by the share extension so there
    // is no need to inspect the identifier beyond the simple check here.
    if ([identifier containsString:WPAppGroupName]) {
        ShareExtensionSessionManager *sessionManager = [[ShareExtensionSessionManager alloc] initWithAppGroup:WPAppGroupName backgroundSessionIdentifier:identifier];
        sessionManager.backgroundSessionCompletionBlock = completionHandler;
        [sessionManager startBackgroundSession];
    }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 120000
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
#else
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
#endif
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        [self handleWebActivity:userActivity];
    } else {
        // Spotlight search
        [SearchManager.shared handleWithActivity: userActivity];
    }

    return YES;
}

#pragma mark - Application startup

- (void)runStartupSequenceWithLaunchOptions:(NSDictionary *)launchOptions
{
    // Crash reporting, logging
    self.logger = [[WPLogger alloc] init];
    [self configureHockeySDK];
    [self configureCrashlytics];
    [self configureAppRatingUtility];

    // Analytics
    [self configureAnalytics];

    // Debugging
    [self printDebugLaunchInfoWithLaunchOptions:launchOptions];
    [self toggleExtraDebuggingIfNeeded];
#if DEBUG
    [KeychainTools processKeychainDebugArguments];
    [ZDKLogger enable:YES];
#endif

    [ZendeskUtils setup];

    // Networking setup
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    [WPUserAgent useWordPressUserAgentInUIWebViews];

    // WORKAROUND: Preload the Noto regular font to ensure it is not overridden
    // by any of the Noto varients.  Size is arbitrary.
    // See: https://github.com/wordpress-mobile/WordPress-Shared-iOS/issues/79
    // Remove this when #79 is resolved.
    [WPFontManager notoRegularFontOfSize:16.0];

    [self customizeAppearance];

    // Push notifications
    // This is silent (the user isn't prompted) so we can do it on launch.
    // We'll ask for user notification permission after signin.
    [[PushNotificationsManager shared] registerForRemoteNotifications];
    
    // Deferred tasks to speed up app launch
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [MediaCoordinator.shared refreshMediaStatus];
        [PostCoordinator.shared refreshPostStatus];
        [MediaFileManager clearUnusedMediaUploadFilesOnCompletion:nil onError:nil];
    });
    
    // Configure Extensions
    [self setupWordPressExtensions];

    [self.shortcutCreator createShortcutsIf3DTouchAvailable:[self isLoggedIn]];
    
    self.window.rootViewController = [WPTabBarController sharedInstance];

    [self configureNoticePresenter];
}

#pragma mark - Push Notification delegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[PushNotificationsManager shared] registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [[PushNotificationsManager shared] registrationDidFail:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DDLogMethod();

    [[PushNotificationsManager shared] handleNotification:userInfo completionHandler:completionHandler];
}

#pragma mark - Background Refresh

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    WPTabBarController *tabBarController = [WPTabBarController sharedInstance];
    ReaderMenuViewController *readerMenuVC = tabBarController.readerMenuViewController;
    if (readerMenuVC.currentReaderStream) {
        [readerMenuVC.currentReaderStream backgroundFetch:completionHandler];
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (BOOL)runningInBackground
{
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    return state == UIApplicationStateBackground;
}

#pragma mark - Custom methods

- (BOOL)isLoggedIn
{
    return !([self noSelfHostedBlogs] && [self noWordPressDotComAccount]);
}

- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated
{
    if ([self isWelcomeScreenVisible] || !([self noSelfHostedBlogs] && [self noWordPressDotComAccount])) {
        return;
    }
    
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

- (void)showWelcomeScreenAnimated:(BOOL)animated thenEditor:(BOOL)thenEditor
{
    [WordPressAuthenticator showLoginFromPresenter:self.window.rootViewController animated:animated];
}

- (void)customizeAppearance
{
    self.window.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    self.window.tintColor = [WPStyleGuide wordPressBlue];
    [WPStyleGuide configureNavigationBarAppearance];

    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [NUXNavigationController class]]] setShadowImage:[UIImage imageWithColor:[UIColor clearColor] havingSize:CGSizeMake(320.0, 4.0)]];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [NUXNavigationController class]]] setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor] havingSize:CGSizeMake(320.0, 4.0)] forBarMetrics:UIBarMetricsDefault];

    [[UITabBar appearance] setShadowImage:[UIImage imageWithColor:[UIColor colorWithRed:210.0/255.0 green:222.0/255.0 blue:230.0/255.0 alpha:1.0]]];
    [[UITabBar appearance] setTintColor:[WPStyleGuide mediumBlue]];

    [[UINavigationBar appearance] setBackgroundImage:[WPStyleGuide navigationBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[WPStyleGuide navigationBarShadowImage]];
    [[UINavigationBar appearance] setBarStyle:[WPStyleGuide navigationBarBarStyle]];

    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont]} forState:UIControlStateNormal];
    [[UIToolbar appearance] setBarTintColor:[WPStyleGuide wordPressBlue]];
    [[UISwitch appearance] setOnTintColor:[WPStyleGuide wordPressBlue]];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [WPStyleGuide grey]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [WPStyleGuide wordPressBlue]} forState:UIControlStateSelected];

    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [UIReferenceLibraryViewController class] ]] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [UIReferenceLibraryViewController class] ]] setBarTintColor:[WPStyleGuide wordPressBlue]];
    [[UIToolbar appearanceWhenContainedInInstancesOfClasses:@[ [UIReferenceLibraryViewController class] ]] setBarTintColor:[UIColor darkGrayColor]];

    // Search
    [WPStyleGuide configureSearchBarAppearance];

    // SVProgressHUD styles
    [SVProgressHUD setBackgroundColor:[[WPStyleGuide littleEddieGrey] colorWithAlphaComponent:0.95]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"hud_error"]];
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hud_success"]];
    
    // Media Picker styles
    UIBarButtonItem *barButtonItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]];
    [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName : [WPFontManager systemSemiBoldFontOfSize:16.0]} forState:UIControlStateDisabled];
    [[UICollectionView appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]] setBackgroundColor:[WPStyleGuide greyLighten30]];

    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]] setLoadingBackgroundColor:[WPStyleGuide lightGrey]];
    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]] setPlaceholderBackgroundColor:[WPStyleGuide darkGrey]];
    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]] setPlaceholderTintColor:[WPStyleGuide greyLighten30]];
    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]] setCellTintColor:[WPStyleGuide wordPressBlue]];

    [[UIButton appearanceWhenContainedInInstancesOfClasses:@[ [WPActionBar class] ]] setTintColor:[WPStyleGuide wordPressBlue]];

    // Customize the appearence of the text elements
    [self customizeAppearanceForTextElements];
}

- (void)customizeAppearanceForTextElements
{
    CGFloat maximumPointSize = [WPStyleGuide maxFontSize];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [UIColor whiteColor],
                                                           NSFontAttributeName: [WPStyleGuide fixedFontFor:UIFontTextStyleHeadline weight:UIFontWeightBold]
                                                           }];
    // Search
    [WPStyleGuide configureSearchBarTextAppearance];
    // SVProgressHUD styles
    [SVProgressHUD setFont:[WPStyleGuide fontForTextStyle:UIFontTextStyleHeadline maximumPointSize:maximumPointSize]];
}

- (void)trackLogoutIfNeeded
{
    if (![self isLoggedIn]) {
        [WPAnalytics track:WPAnalyticsStatLogout];
    }
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

#pragma mark - Log Level

+ (void)setLogLevel:(DDLogLevel)logLevel
{
    ddLogLevel = logLevel;

    int logLevelInt = (int)logLevel;
    WPSharedSetLoggingLevel(logLevelInt);
    TracksSetLoggingLevel(logLevelInt);
    WPStatsSetLoggingLevel(logLevelInt);
    WPAuthenticatorSetLoggingLevel(logLevelInt);
}

@end
