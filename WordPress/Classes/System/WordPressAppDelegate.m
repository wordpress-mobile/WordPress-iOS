#import "WordPressAppDelegate.h"

// Constants
#import "Constants.h"

// Pods
#import <AFNetworking/UIKit+AFNetworking.h>
#import <Crashlytics/Crashlytics.h>
#import <HockeySDK/HockeySDK.h>
#import <Reachability/Reachability.h>
#import <Simperium/Simperium.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import <WordPressApi/WordPressApi.h>
#import <WordPress_AppbotX/ABX.h>
#import <WordPressShared/UIImage+Util.h>

// Analytics & crash logging
#import "WPAppAnalytics.h"
#import "WPCrashlytics.h"

// Categories & extensions
#import "NSBundle+VersionNumberHelper.h"
#import "NSProcessInfo+Util.h"
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
#import "AppRatingUtility.h"
#import "ContextManager.h"
#import "HelpshiftUtils.h"
#import "WPLookbackPresenter.h"
#import "TodayExtensionService.h"
#import "WPAuthTokenIssueSolver.h"

// Networking
#import "WPUserAgent.h"
#import "WordPressComApiCredentials.h"

// Swift support
#import "WordPress-Swift.h"

// View controllers
#import "RotationAwareNavigationViewController.h"
#import "LoginViewController.h"
#import "ReaderViewController.h"
#import "StatsViewController.h"
#import "SupportViewController.h"
#import "WPPostViewController.h"
#import "WPTabBarController.h"
#import <WPMediaPicker/WPMediaPicker.h>

int ddLogLevel                                                  = DDLogLevelInfo;

@interface WordPressAppDelegate () <UITabBarControllerDelegate, UIAlertViewDelegate, BITHockeyManagerDelegate>

@property (nonatomic, strong, readwrite) WPAppAnalytics                 *analytics;
@property (nonatomic, strong, readwrite) WPCrashlytics                  *crashlytics;
@property (nonatomic, strong, readwrite) WPLogger                       *logger;
@property (nonatomic, strong, readwrite) WPLookbackPresenter            *lookbackPresenter;
@property (nonatomic, strong, readwrite) Reachability                   *internetReachability;
@property (nonatomic, strong, readwrite) Simperium                      *simperium;
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier     bgTask;
@property (nonatomic, assign, readwrite) BOOL                           connectionAvailable;
@property (nonatomic, strong, readwrite) WPUserAgent                    *userAgent;
@property (nonatomic, assign, readwrite) BOOL                           shouldRestoreApplicationState;
@property (nonatomic, assign) UIApplicationShortcutItem                 *launchedShortcutItem;

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
    [WordPressAppDelegate fixKeychainAccess];

    // Basic networking setup
    [self setupReachability];
    
    // Set the main window up
    [self.window makeKeyAndVisible];
    
    // Simperium: Wire CoreData Stack
    [self configureSimperiumWithLaunchOptions:launchOptions];
    
    // Local Notifications
    [self listenLocalNotifications];

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
        
        NSString *lookbackToken = [WordPressComApiCredentials lookbackToken];
        
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
    if ([WordPressComApiCredentials appbotXAPIKey].length > 0) {
        [[ABXApiClient instance] setApiKey:[WordPressComApiCredentials appbotXAPIKey]];
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    DDLogInfo(@"Application launched with URL: %@", url);
    BOOL returnValue = NO;

    NSString *sourceApplication = [options stringForKey:UIApplicationLaunchOptionsSourceApplicationKey];
    id annotation = [options objectForKey:UIApplicationLaunchOptionsAnnotationKey];
    if ([[BITHockeyManager sharedHockeyManager].authenticator handleOpenURL:url
                                                          sourceApplication:sourceApplication
                                                                 annotation:annotation]) {
        returnValue = YES;
    }

    if ([WordPressApi handleOpenURL:url]) {
        returnValue = YES;
    }

    if ([url isKindOfClass:[NSURL class]] && [[url absoluteString] hasPrefix:WPComScheme]) {
        NSString *URLString = [url absoluteString];

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
    
    if (self.launchedShortcutItem) {
        WP3DTouchShortcutHandler *shortcutHandler = [[WP3DTouchShortcutHandler alloc] init];
        [shortcutHandler handleShortcutItem:self.launchedShortcutItem];
        self.launchedShortcutItem = nil;
    }
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return self.shouldRestoreApplicationState;
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
    
    // Start Simperium
    [self loginSimperium];
    
    // Debugging
    [self printDebugLaunchInfoWithLaunchOptions:launchOptions];
    [self toggleExtraDebuggingIfNeeded];
    [self removeCredentialsForDebug];
    
    // Stats and feedback
    [SupportViewController checkIfFeedbackShouldBeEnabled];
    
    [HelpshiftUtils setup];
    
    // Networking setup
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    self.userAgent = [[WPUserAgent alloc] init];
    [self.userAgent useWordPressUserAgentInUIWebViews];
    [self setupSingleSignOn];

    // WORKAROUND: Preload the Merriweather regular font to ensure it is not overridden
    // by any of the Merriweather varients.  Size is arbitrary.
    // See: https://github.com/wordpress-mobile/WordPress-Shared-iOS/issues/79
    // Remove this when #79 is resolved.
    [WPFontManager merriweatherRegularFontOfSize:16.0];

    [self customizeAppearance];

    // Notifications
    [[PushNotificationsManager sharedInstance] registerForRemoteNotifications];
    [[InteractiveNotificationsHandler sharedInstance] registerForUserNotifications];
    
    // Deferred tasks to speed up app launch
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [MediaService cleanUnusedMediaFileFromTmpDir];
    });
    
    // Configure Today Widget
    [self determineIfTodayWidgetIsConfiguredAndShowAppropriately];
    
    [WPPostViewController makeNewEditorAvailable];
    
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

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier
                                        forRemoteNotification:(NSDictionary *)remoteNotification
                                            completionHandler:(void (^)())completionHandler
{
    [[InteractiveNotificationsHandler sharedInstance] handleActionWithIdentifier:identifier remoteNotification:remoteNotification];
    
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
        
        if ([key isEqualToString:WPNewPostURLParamContentKey]) {
            value = [value stringByStrippingHTML];
        } else if ([key isEqualToString:WPNewPostURLParamTagsKey]) {
            value = [value stringByStrippingHTML];
        }
        
        [sanitizedDictionary setObject:value forKey:key];
    }
    
    return [NSDictionary dictionaryWithDictionary:sanitizedDictionary];
}

#pragma mark - Custom methods

- (BOOL)isLoggedIn
{
    return !([self noSelfHostedBlogs] && [self noWordPressDotComAccount]);
}

- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated
{
    if (self.isWelcomeScreenVisible || !([self noSelfHostedBlogs] && [self noWordPressDotComAccount])) {
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
    BOOL hasWordpressAccountButNoSelfHostedBlogs = [self noSelfHostedBlogs] && ![self noWordPressDotComAccount];
    
    __weak __typeof(self) weakSelf = self;
    
    LoginViewController *loginViewController = [[LoginViewController alloc] init];
    loginViewController.showEditorAfterAddingSites = thenEditor;
    loginViewController.cancellable = hasWordpressAccountButNoSelfHostedBlogs;
    loginViewController.dismissBlock = ^(BOOL cancelled){
        
        __strong __typeof(weakSelf) strongSelf = self;
        
        [strongSelf.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    };

    UINavigationController *navigationController = [[RotationAwareNavigationViewController alloc] initWithRootViewController:loginViewController];
    navigationController.navigationBar.translucent = NO;

    [self.window.rootViewController presentViewController:navigationController animated:animated completion:nil];
}

- (BOOL)isWelcomeScreenVisible
{
    UINavigationController *presentedViewController = (UINavigationController *)self.window.rootViewController.presentedViewController;
    if (![presentedViewController isKindOfClass:[UINavigationController class]]) {
        return NO;
    }
    
    return [presentedViewController.visibleViewController isKindOfClass:[LoginViewController class]];
}

- (BOOL)noWordPressDotComAccount
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    return !defaultAccount;
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
    UIColor *defaultTintColor = self.window.tintColor;
    self.window.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    self.window.tintColor = [WPStyleGuide wordPressBlue];

    [[UINavigationBar appearance] setBarTintColor:[WPStyleGuide wordPressBlue]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [MFMailComposeViewController class] ]] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[ [MFMailComposeViewController class] ]] setTintColor:defaultTintColor];

    [[UITabBar appearance] setShadowImage:[UIImage imageWithColor:[UIColor colorWithRed:210.0/255.0 green:222.0/255.0 blue:230.0/255.0 alpha:1.0]]];
    [[UITabBar appearance] setTintColor:[WPStyleGuide newKidOnTheBlockBlue]];

    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [WPFontManager systemBoldFontOfSize:17.0]} ];

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

    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[ [UISearchBar class] ]] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[WPStyleGuide littleEddieGrey]]];
    
    // SVProgressHUD styles    
    [SVProgressHUD setBackgroundColor:[[WPStyleGuide littleEddieGrey] colorWithAlphaComponent:0.95]];
    [SVProgressHUD setForegroundColor:[UIColor whiteColor]];
    [SVProgressHUD setFont:[WPFontManager systemRegularFontOfSize:18.0]];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"hud_error"]];
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hud_success"]];
    
    // Media Picker styles
    UIBarButtonItem *barButtonItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]];
    [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName : [WPFontManager systemSemiBoldFontOfSize:16.0]} forState:UIControlStateNormal];
    [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName : [WPFontManager systemSemiBoldFontOfSize:16.0]} forState:UIControlStateDisabled];
    [[UICollectionView appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaPickerViewController class] ]] setBackgroundColor:[WPStyleGuide greyLighten30]];
    [[WPMediaCollectionViewCell appearanceWhenContainedInInstancesOfClasses:@[ [WPMediaCollectionViewController class] ]] setBackgroundColor:[WPStyleGuide lightGrey]];
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
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [AppRatingUtility registerSection:@"notifications" withSignificantEventCount:5];
    [AppRatingUtility setSystemWideSignificantEventsCount:10];
    [AppRatingUtility initializeForVersion:version];
    [AppRatingUtility checkIfAppReviewPromptsHaveBeenDisabled:nil failure:^{
        DDLogError(@"Was unable to retrieve data about throttling");
    }];
}

#pragma mark - Crashlytics configuration

- (void)configureCrashlytics
{
#if defined(INTERNAL_BUILD) || defined(DEBUG)
    return;
#endif
    
    NSString* apiKey = [WordPressComApiCredentials crashlyticsApiKey];
    
    if (apiKey) {
        self.crashlytics = [[WPCrashlytics alloc] initWithAPIKey:apiKey];
    }
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
    NSString *description = [self.logger getLogFilesContentWithMaxSize:5000]; // 5000 bytes should be enough!
    if ([description length] == 0) {
        return nil;
    }

    return description;
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
    
    self.simperium.verboseLoggingEnabled = NO;
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

#pragma mark - Debugging

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
}

- (void)handleDefaultAccountChangedNote:(NSNotification *)notification
{
    // If the notification object is not nil, then it's a login
    if (notification.object) {
        [self loginSimperium];
    } else {
        if ([self noSelfHostedBlogs] && [self noWordPressDotComAccount]) {
            [WPAnalytics track:WPAnalyticsStatLogout];
        }
        
        if (self.simperium.user.authenticated) {
            [self logoutSimperiumAndResetNotifications];
        } else {
            [self resetSimperiumOnAuthTokenIssue];
        }
        
        [self removeTodayWidgetConfiguration];
        [self showWelcomeScreenIfNeededAnimated:NO];
    }
    
    [self create3DTouchShortcutItems];
    [self toggleExtraDebuggingIfNeeded];
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

#pragma mark - Simperium helpers

/**
 *  @brief      This code exists for the sole purpose of fixing the missing-auth-token issue in
 *              WPiOS 5.3.
 *  @details    Read this: https://github.com/wordpress-mobile/WordPress-iOS/issues/3964
 *  @todo       Remove this once enough version numbers have passed :)
 */
- (void)resetSimperiumOnAuthTokenIssue
{
    SPBucket *notesBucket = [self.simperium bucketForName:NSStringFromClass([Notification class])];
    [notesBucket deleteAllObjects];
    [self.simperium saveWithoutSyncing];
}

- (BOOL)testSuiteIsRunning
{
    Class testSuite = NSClassFromString(@"XCTestCase");
    return testSuite != nil;
}

@end
