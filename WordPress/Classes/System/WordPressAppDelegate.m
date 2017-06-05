#import "WordPressAppDelegate.h"

// Constants
#import "Constants.h"

// Pods
#import <AFNetworking/UIKit+AFNetworking.h>
#import <Crashlytics/Crashlytics.h>
#import <Reachability/Reachability.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import <WordPress_AppbotX/ABX.h>
#import <WordPressShared/UIImage+Util.h>

#ifdef BUDDYBUILD_ENABLED
#import <BuddyBuildSDK/BuddyBuildSDK.h>
#endif


// Analytics & crash logging
#import "WPAppAnalytics.h"
#import "WPCrashlytics.h"

// Categories & extensions
#import "NSBundle+VersionNumberHelper.h"
#import "NSString+Helpers.h"
#import "UIDevice+Helpers.h"

// Data model
#import "Blog.h"

// Data services
#import "BlogService.h"
#import "MediaService.h"

// Logging
#import "WPLogger.h"

// Misc managers, helpers, utilities
#import "ContextManager.h"
#import "HelpshiftUtils.h"
#import "HockeyManager.h"
#import "WPLookbackPresenter.h"
#import "TodayExtensionService.h"
#import "WPAuthTokenIssueSolver.h"

// Networking
#import "WPUserAgent.h"
#import "ApiCredentials.h"

// Swift support
#import "WordPress-Swift.h"

// View controllers
#import "RotationAwareNavigationViewController.h"
#import "StatsViewController.h"
#import "SupportViewController.h"
#import "WPPostViewController.h"
#import "WPTabBarController.h"
#import <WPMediaPicker/WPMediaPicker.h>
#import <WordPressEditor/WPLegacyEditorFormatToolbar.h>

int ddLogLevel = DDLogLevelInfo;

@interface WordPressAppDelegate () <UITabBarControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong, readwrite) WPAppAnalytics                 *analytics;
@property (nonatomic, strong, readwrite) WPCrashlytics                  *crashlytics;
@property (nonatomic, strong, readwrite) WPLogger                       *logger;
@property (nonatomic, strong, readwrite) WPLookbackPresenter            *lookbackPresenter;
@property (nonatomic, strong, readwrite) Reachability                   *internetReachability;
@property (nonatomic, strong, readwrite) HockeyManager                  *hockey;
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier     bgTask;
@property (nonatomic, assign, readwrite) BOOL                           connectionAvailable;
@property (nonatomic, assign, readwrite) BOOL                           shouldRestoreApplicationState;
@property (nonatomic, strong, readwrite) PingHubManager                 *pinghubManager;

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

    // Basic networking setup
    [self setupReachability];
    
    // Set the main window up
    [self.window makeKeyAndVisible];

    // Local Notifications
    [self listenLocalNotifications];

    WPAuthTokenIssueSolver *authTokenIssueSolver = [[WPAuthTokenIssueSolver alloc] init];
    
    __weak __typeof(self) weakSelf = self;

    BOOL isFixingAuthTokenIssue = [authTokenIssueSolver fixAuthTokenIssueAndDo:^{
        [weakSelf runStartupSequenceWithLaunchOptions:launchOptions];
    }];

    self.shouldRestoreApplicationState = !isFixingAuthTokenIssue;

    // Temporary force of Aztec to "on" for all internal users
#ifdef INTERNAL_BUILD
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *defaultsKey = @"AztecInternalForceOnVersion";
    NSString *lastBuildAztecForcedOn = [defaults stringForKey:defaultsKey];
    NSString *currentVersion = [[NSBundle mainBundle] bundleVersion];
    if (![currentVersion isEqualToString:lastBuildAztecForcedOn]) {
        [defaults setObject:currentVersion forKey:defaultsKey];
        [defaults synchronize];

        EditorSettings *settings = [EditorSettings new];
        [settings setNativeEditorAvailable:TRUE];
        [settings setVisualEditorEnabled:TRUE];
        [settings setNativeEditorEnabled:TRUE];
    }
#endif

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    DDLogVerbose(@"didFinishLaunchingWithOptions state: %d", application.applicationState);

    [[InteractiveNotificationsManager sharedInstance] registerForUserNotifications];
    [self showWelcomeScreenIfNeededAnimated:NO];
    [self setupLookback];
    [self setupAppbotX];
    [self setupStoreKit];
    [self setupBuddyBuild];
    [self setupPingHub];
    [self setupBackgroundRefresh:application];

    return YES;
}

- (void)setupLookback
{
#ifdef LOOKBACK_ENABLED
    // Kick this off on a background thread so as to not slow down the app initialization
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSString *lookbackToken = [ApiCredentials lookbackToken];
        
        if ([lookbackToken length] > 0) {
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;

            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            
            [context performBlock:^{
                AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
                WPAccount *account = [accountService defaultWordPressComAccount];

                self.lookbackPresenter = [[WPLookbackPresenter alloc] initWithToken:lookbackToken
                                                                             userId:account.username
                                                                             window:keyWindow];
            }];
        }
    });
#endif
}

- (void)setupAppbotX
{
    if ([ApiCredentials appbotXAPIKey].length > 0) {
        [[ABXApiClient instance] setApiKey:[ApiCredentials appbotXAPIKey]];
    }
}

- (void)setupStoreKit
{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[StoreKitTransactionObserver instance]];
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

- (void)setupBackgroundRefresh:(UIApplication *)application {
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    DDLogInfo(@"Application launched with URL: %@", url);
    BOOL returnValue = NO;

    if ([self.hockey handleOpenURL:url options:options]) {
        returnValue = YES;
    }

    if ([url isKindOfClass:[NSURL class]] && [[url absoluteString] hasPrefix:WPComScheme]) {
        NSString *URLString = [url absoluteString];
            
        if ([URLString rangeOfString:@"magic-login"].length) {
            DDLogInfo(@"App launched with authentication link");
            returnValue = [SigninHelpers openAuthenticationURL:url fromRootViewController:self.window.rootViewController];
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
        } else if ([[url host] isEqualToString:@"faq"]) {
            if ([HelpshiftUtils isHelpshiftEnabled]) {
                NSString *faqID = [url lastPathComponent];

                UIViewController *viewController = self.window.topmostPresentedViewController;

                if (viewController) {
                    HelpshiftPresenter *presenter = [HelpshiftPresenter new];
                    [presenter presentHelpshiftWindowForFAQ:faqID
                                         fromViewController:viewController
                                                 completion:nil];
                }

                return YES;
            }
        } else if ([[url host] isEqualToString:@"editor"] || [[url host] isEqualToString:@"aztec"]) {
            // Example: wordpress://editor?available=1&enabled=0
            NSDictionary* params = [[url query] dictionaryFromQueryString];

            if (params.count > 0) {
                BOOL available = [[params objectForKey:@"available"] boolValue];
                BOOL enabled = [[params objectForKey:@"enabled"] boolValue];

                EditorSettings *editorSettings = [EditorSettings new];
                editorSettings.nativeEditorAvailable = available;
                editorSettings.nativeEditorEnabled = enabled;
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
        } else if ([firstViewController isKindOfClass:[NUXAbstractViewController class]]) {
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

#pragma mark - Application startup

- (void)runStartupSequenceWithLaunchOptions:(NSDictionary *)launchOptions
{
    // Crash reporting, logging
    self.logger = [[WPLogger alloc] init];
    [self configureHockeySDK];
    [self configureCrashlytics];
    [self initializeAppRatingUtility];
    
    // Analytics
    [self configureAnalytics];

    // Debugging
    [self printDebugLaunchInfoWithLaunchOptions:launchOptions];
    [self toggleExtraDebuggingIfNeeded];
    [self removeCredentialsForDebug];
#if DEBUG
    [KeychainTools processKeychainDebugArguments];
#endif

    [HelpshiftUtils setup];
    
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
    // This is silent (the user is prompted) so we can do it on launch.
    // We'll ask for user notification permission after signin.
    [[PushNotificationsManager sharedInstance] registerForRemoteNotifications];
    
    // Deferred tasks to speed up app launch
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [MediaLibrary clearUnusedFilesFromLocalDirectoryOnCompletion:nil onError:nil];
    });
    
    // Configure Extensions
    [self setupWordPressExtensions];

    [self create3DTouchShortcutItems];
    
    self.window.rootViewController = [WPTabBarController sharedInstance];
}

#pragma mark - Push Notification delegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[PushNotificationsManager sharedInstance] registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [[PushNotificationsManager sharedInstance] registrationDidFail:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    DDLogMethod();

    [[PushNotificationsManager sharedInstance] handleNotification:userInfo completionHandler:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DDLogMethod();

    [[PushNotificationsManager sharedInstance] handleNotification:userInfo completionHandler:completionHandler];
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
    [SigninHelpers showSigninFromPresenter:self.window.rootViewController animated:animated thenEditor:thenEditor];
}

- (BOOL)isWelcomeScreenVisible
{
    UINavigationController *presentedViewController = (UINavigationController *)self.window.rootViewController.presentedViewController;
    if (![presentedViewController isKindOfClass:[UINavigationController class]]) {
        return NO;
    }

    if ([presentedViewController isKindOfClass:[NUXNavigationController class]]) {
        return YES;
    }

    return [presentedViewController.visibleViewController isKindOfClass:[NUXAbstractViewController class]];
}

- (BOOL)noWordPressDotComAccount
{
    return [AccountHelper isDotcomAvailable] == false;
}

- (BOOL)noSelfHostedBlogs
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    
    NSInteger blogCount = [blogService blogCountSelfHosted];
    return blogCount == 0;
}


- (void)customizeAppearance
{
    self.window.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    self.window.tintColor = [WPStyleGuide wordPressBlue];

    [[UINavigationBar appearance] setBarTintColor:[WPStyleGuide wordPressBlue]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [NUXNavigationController class]]] setShadowImage:[UIImage imageWithColor:[UIColor clearColor] havingSize:CGSizeMake(320.0, 4.0)]];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [NUXNavigationController class]]] setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor] havingSize:CGSizeMake(320.0, 4.0)] forBarMetrics:UIBarMetricsDefault];

    [[UITabBar appearance] setShadowImage:[UIImage imageWithColor:[UIColor colorWithRed:210.0/255.0 green:222.0/255.0 blue:230.0/255.0 alpha:1.0]]];
    [[UITabBar appearance] setTintColor:[WPStyleGuide newKidOnTheBlockBlue]];

    [[UINavigationBar appearance] setBackgroundImage:[WPStyleGuide navigationBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[WPStyleGuide navigationBarShadowImage]];
    [[UINavigationBar appearance] setBarStyle:[WPStyleGuide navigationBarBarStyle]];

    [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPFontManager systemRegularFontOfSize:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPFontManager systemRegularFontOfSize:17.0], NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.25]} forState:UIControlStateDisabled];

    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont]} forState:UIControlStateNormal];
    [[UIToolbar appearance] setBarTintColor:[WPStyleGuide wordPressBlue]];
    [[UISwitch appearance] setOnTintColor:[WPStyleGuide wordPressBlue]];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPFontManager systemRegularFontOfSize:10.0], NSForegroundColorAttributeName: [WPStyleGuide allTAllShadeGrey]} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [WPStyleGuide wordPressBlue]} forState:UIControlStateSelected];

    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [UIReferenceLibraryViewController class] ]] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [UIReferenceLibraryViewController class] ]] setBarTintColor:[WPStyleGuide wordPressBlue]];
    [[UIToolbar appearanceWhenContainedInInstancesOfClasses:@[ [UIReferenceLibraryViewController class] ]] setBarTintColor:[UIColor darkGrayColor]];
    
    [[UIToolbar appearanceWhenContainedInInstancesOfClasses:@[ [WPEditorViewController class] ]] setBarTintColor:[UIColor whiteColor]];

    // Search
    [WPStyleGuide configureSearchBarAppearance];

    // SVProgressHUD styles
    [SVProgressHUD setBackgroundColor:[[WPStyleGuide littleEddieGrey] colorWithAlphaComponent:0.95]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"hud_error"]];
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hud_success"]];
    
    // Media Picker styles
    UIBarButtonItem *barButtonItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]];
    [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName : [WPFontManager systemSemiBoldFontOfSize:16.0]} forState:UIControlStateNormal];
    [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName : [WPFontManager systemSemiBoldFontOfSize:16.0]} forState:UIControlStateDisabled];
    [[UICollectionView appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]] setBackgroundColor:[WPStyleGuide greyLighten30]];
    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]] setBackgroundColor:[WPStyleGuide lightGrey]];

    [[WPLegacyEditorFormatToolbar appearance] setBarTintColor:[UIColor colorWithHexString:@"F9FBFC"]];
    [[WPLegacyEditorFormatToolbar appearance] setTintColor:[WPStyleGuide greyLighten10]];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[WPLegacyEditorFormatToolbar class]]] setTintColor:[WPStyleGuide greyLighten10]];

    // Customize the appearence of the text elements
    [self customizeAppearanceForTextElements];
}

- (void)customizeAppearanceForTextElements
{
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [WPStyleGuide fontForTextStyle:UIFontTextStyleHeadline symbolicTraits:UIFontDescriptorTraitBold]} ];
    // Search
    [WPStyleGuide configureSearchBarTextAppearance];
    // SVProgressHUD styles
    [SVProgressHUD setFont:[WPStyleGuide fontForTextStyle:UIFontTextStyleHeadline]];
}

- (void)create3DTouchShortcutItems
{
    WP3DTouchShortcutCreator *shortcutCreator = [WP3DTouchShortcutCreator new];
    [shortcutCreator createShortcutsIf3DTouchAvailable:[self isLoggedIn]];
}

#pragma mark - Analytics

- (void)configureAnalytics
{
    __weak __typeof(self) weakSelf = self;
 
    self.analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:^NSString*{
        return [weakSelf currentlySelectedScreen];
    }];
}

#pragma mark - App Rating

- (void)initializeAppRatingUtility
{
    AppRatingUtility *utility = [AppRatingUtility shared];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [utility registerSection:@"notifications" withSignificantEventCount:5];
    utility.systemWideSignificantEventCountRequiredForPrompt = 10;
    [utility setVersion:version];
    [utility checkIfAppReviewPromptsHaveBeenDisabledWithSuccess:nil failure:^{
        DDLogError(@"Was unable to retrieve data about throttling");
    }];
}

#pragma mark - Crashlytics configuration

- (void)configureCrashlytics
{
#if defined(DEBUG)
    return;
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    NSString* apiKey = [ApiCredentials crashlyticsApiKey];
    
    if (apiKey) {
        self.crashlytics = [[WPCrashlytics alloc] initWithAPIKey:apiKey];
    }
#pragma clang diagnostic pop
}

- (void)configureHockeySDK
{
    self.hockey = [HockeyManager new];
    [self.hockey configure];
}

#pragma mark - Networking setup

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

#pragma mark - Debugging

- (void)printDebugLaunchInfoWithLaunchOptions:(NSDictionary *)launchOptions
{
    UIDevice *device = [UIDevice currentDevice];
    NSInteger crashCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"crashCount"];
    NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    NSString *currentLanguage = [languages objectAtIndex:0];
    BOOL extraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    NSArray *blogs = [blogService blogsForAllAccounts];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *account = [accountService defaultWordPressComAccount];
    
    DDLogInfo(@"===========================================================================");
    DDLogInfo(@"Launching WordPress for iOS %@...", [[NSBundle bundleForClass:[self class]] detailedVersionNumber]);
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
    DDLogInfo(@"APN token: %@", [[PushNotificationsManager sharedInstance] deviceToken]);
    DDLogInfo(@"Launch options: %@", launchOptions);
    NSString *verificationTag = @"";
    if (account.verificationStatus) {
        verificationTag = [NSString stringWithFormat:@" (%@)", account.verificationStatus];
    }
    DDLogInfo(@"wp.com account: %@ (ID: %@)%@", account.username, account.userID, verificationTag);
    
    if (blogs.count > 0) {
        DDLogInfo(@"All blogs on device:");
        for (Blog *blog in blogs) {
            DDLogInfo(@"%@", [blog logDescription]);
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

- (void)toggleExtraDebuggingIfNeeded
{
    if ([self noSelfHostedBlogs] && [self noWordPressDotComAccount]) {
        // When there are no blogs in the app the settings screen is unavailable.
        // In this case, enable extra_debugging by default to help troubleshoot any issues.
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"orig_extra_debug"] != nil) {
            return; // Already saved. Don't save again or we could loose the original value.
        }

        NSString *origExtraDebug = [[NSUserDefaults standardUserDefaults] boolForKey:@"extra_debug"] ? @"YES" : @"NO";
        [[NSUserDefaults standardUserDefaults] setObject:origExtraDebug forKey:@"orig_extra_debug"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"extra_debug"];
        ddLogLevel = DDLogLevelVerbose;
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
            ddLogLevel = DDLogLevelVerbose;
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

    [notificationCenter addObserver:self
                           selector:@selector(handleUIContentSizeCategoryDidChangeNotification:)
                               name:UIContentSizeCategoryDidChangeNotification
                             object:nil];
}

- (void)handleDefaultAccountChangedNote:(NSNotification *)notification
{
    // If the notification object is not nil, then it's a login
    if (notification.object) {
        [self setupShareExtensionToken];
    } else {
        if ([self noSelfHostedBlogs] && [self noWordPressDotComAccount]) {
            [WPAnalytics track:WPAnalyticsStatLogout];
        }

        [self removeTodayWidgetConfiguration];
        [self removeShareExtensionConfiguration];
        [self showWelcomeScreenIfNeededAnimated:NO];
    }
    
    [self create3DTouchShortcutItems];
    [self toggleExtraDebuggingIfNeeded];
    
    [WPAnalytics track:WPAnalyticsStatDefaultAccountChanged];
}

- (void)handleLowMemoryWarningNote:(NSNotification *)notification
{
    [WPAnalytics track:WPAnalyticsStatLowMemoryWarning];
}

- (void)handleUIContentSizeCategoryDidChangeNotification:(NSNotification *)notification
{
    [self customizeAppearanceForTextElements];
}

#pragma mark - Extensions

- (void)setupWordPressExtensions
{
    // Default Account
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    [accountService setupAppExtensionsWithDefaultAccount];

    // Settings
    NSInteger maxImageSize = [[MediaSettings new] maxImageSizeSetting];
    [ShareExtensionService configureShareExtensionMaximumMediaDimension:maxImageSize];
}


#pragma mark - Today Extension

- (void)removeTodayWidgetConfiguration
{
    TodayExtensionService *service = [TodayExtensionService new];
    [service removeTodayWidgetConfiguration];
}


#pragma mark - Share Extension

- (void)setupShareExtensionToken
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService  = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *account              = [accountService defaultWordPressComAccount];
    
    [ShareExtensionService configureShareExtensionToken:account.authToken];
    [ShareExtensionService configureShareExtensionUsername:account.username];
}

- (void)removeShareExtensionConfiguration
{
    [ShareExtensionService removeShareExtensionConfiguration];
}

@end
