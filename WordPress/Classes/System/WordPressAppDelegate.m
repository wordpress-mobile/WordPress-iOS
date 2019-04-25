#import "WordPressAppDelegate.h"

// Constants
#import "Constants.h"

// Pods
#import <Crashlytics/Crashlytics.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <WordPressUI/WordPressUI.h>

// Data model
#import "Blog.h"

// Data services
#import "BlogService.h"
#import "MediaService.h"

// Logging
#import "WPLogger.h"

// Misc managers, helpers, utilities
#import "ContextManager.h"
#import "TodayExtensionService.h"
#import "WPAuthTokenIssueSolver.h"
#import <ZendeskCoreSDK/ZendeskCoreSDK.h>

// Networking
#import "WPUserAgent.h"
#import "ApiCredentials.h"

// Swift support
#import "WordPress-Swift.h"

// View controllers
#import "StatsViewController.h"
#import "WPTabBarController.h"
#import <WPMediaPicker/WPMediaPicker.h>


@interface WordPressAppDelegate1 () <UITabBarControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong, readwrite) WPLogger                       *logger;
@property (nonatomic, assign, readwrite) UIBackgroundTaskIdentifier     bgTask;
@property (nonatomic, assign, readwrite) BOOL                           shouldRestoreApplicationState;
@property (nonatomic, strong, readwrite) PingHubManager                 *pinghubManager;
@property (nonatomic, strong, readwrite) WP3DTouchShortcutCreator       *shortcutCreator;
@property (nonatomic, strong, readwrite) NoticePresenter                *noticePresenter;

@end

@implementation WordPressAppDelegate1

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    return YES; //[self application:app open:url options:options];
}

#pragma mark - Application startup

- (void)runStartupSequenceWithLaunchOptions1:(NSDictionary *)launchOptions
{/*
    // Local Notifications
    [self addNotificationObservers];
    
    // Crash reporting, logging
    self.logger = [[WPLogger alloc] init];
    [self configureHockeySDK];
    [self configureCrashlytics];
    [self configureAppRatingUtility];

    // Analytics
    [self configureAnalytics];

    // Debugging
    [self printDebugLaunchInfoWithLaunchOptions:launchOptions];
    [self toggleExtraDebuggingIfNeeded];*/
#if DEBUG
    [KeychainTools processKeychainDebugArguments];
    [ZDKCoreLogger setEnabled:YES];
    [ZDKCoreLogger setLogLevel:ZDKLogLevelDebug];
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

//    [self customizeAppearance];

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
//    [self setupWordPressExtensions];

    [self.shortcutCreator createShortcutsIf3DTouchAvailable:[AccountHelper isLoggedIn]];
    
    self.window.rootViewController = [WPTabBarController sharedInstance];

//    [self configureNoticePresenter];
}

@end
