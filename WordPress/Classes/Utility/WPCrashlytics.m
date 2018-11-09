#import "WPCrashlytics.h"

@import Crashlytics;

#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "WPAccount.h"
#import "WPAppAnalytics.h"

NSString * const WPCrashlyticsDefaultsUserOptedOut = @"crashlytics_opt_out";
NSString * const WPCrashlyticsKeyLoggedIn = @"logged_in";
NSString * const WPCrashlyticsKeyConnectedToDotcom = @"connected_to_dotcom";
NSString * const WPCrashlyticsKeyNumberOfBlogs = @"number_of_blogs";

@interface WPCrashlytics () <CrashlyticsDelegate>
@end

@implementation WPCrashlytics

#pragma mark - Initialization

- (instancetype)initWithAPIKey:(NSString *)apiKey
{
    NSParameterAssert(apiKey);
    
    self = [super init];
    
    if (self) {
        [self startupCrashlyticsIfNeeded];
        [self startObservingNotifications];
    }
    
    return self;
}

#pragma mark - Init helpers

/**
 *  @brief      Start crashlytics for WPiOS
 */
- (void)startupCrashlyticsIfNeeded
{
    [self initializeOptOutTracking];

    BOOL userHasOptedOut = [WPCrashlytics userHasOptedOut];
    if (!userHasOptedOut) {
        // See also : https://docs.fabric.io/apple/crashlytics/advanced-setup.html
        [CrashlyticsKit setDelegate:self];

        // See also : https://docs.fabric.io/apple/fabric/advanced-settings/debugging.html
        #if DEBUG
            [[Fabric sharedSDK] setDebug:YES];
        #endif

        // FYI: This method may get called mutiple times (e.g. user toggles the privacy settings on-off-on).
        // Per the docs, only the first call is honored and subsequent calls are no-ops.
        [Fabric with:@[CrashlyticsKit]];

        [self setCommonCrashlyticsParameters];
    }
}

#pragma mark - Tracks Opt Out

- (void)initializeOptOutTracking {
    if ([WPCrashlytics userHasOptedOutIsSet]) {
        // We've already configured the opt out setting
        return;
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:WPAppAnalyticsDefaultsUserOptedOut] == YES) {
        // If the user has already explicitly disabled tracking for analytics, let's ensure we turn off Crashlytics tracking as well
        [self setUserHasOptedOutValue:YES];
    } else {
        [self setUserHasOptedOutValue:NO];
    }
}

/// This method just sets the user defaults value for UserOptedOut, and doesn't do any additional configuration
///
- (void)setUserHasOptedOutValue:(BOOL)optedOut
{
    [[NSUserDefaults standardUserDefaults] setBool:optedOut forKey:WPCrashlyticsDefaultsUserOptedOut];
}

+ (BOOL)userHasOptedOutIsSet {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WPCrashlyticsDefaultsUserOptedOut] != nil;
}

+ (BOOL)userHasOptedOut {
    return [[NSUserDefaults standardUserDefaults] boolForKey:WPCrashlyticsDefaultsUserOptedOut];
}

- (void)setUserHasOptedOut:(BOOL)optedOut
{
    if ([WPCrashlytics userHasOptedOutIsSet]) {
        BOOL currentValue = [WPCrashlytics userHasOptedOut];
        if (currentValue == optedOut) {
            return;
        }
    }

    [self setUserHasOptedOutValue:optedOut];

    if (optedOut) {
        [self clearCommonCrashlyticsParameters];
    } else {
        [self startupCrashlyticsIfNeeded];
    }
}

#pragma mark - Notifications

- (void)startObservingNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleDefaultAccountChangedNotification:)
                               name:WPAccountDefaultWordPressComAccountChangedNotification
                             object:nil];
}

- (void)handleDefaultAccountChangedNotification:(NSNotification *)notification
{
    BOOL userHasOptedOut = [WPCrashlytics userHasOptedOut];
    if (!userHasOptedOut) {
        [self setCommonCrashlyticsParameters];
    }
}

#pragma mark - Common crashlytics parameters

- (void)setCommonCrashlyticsParameters
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    BOOL loggedIn = defaultAccount != nil;
    [CrashlyticsKit setUserName:defaultAccount.username];
    [CrashlyticsKit setObjectValue:@(loggedIn) forKey:WPCrashlyticsKeyLoggedIn];
    [CrashlyticsKit setObjectValue:@(loggedIn) forKey:WPCrashlyticsKeyConnectedToDotcom];
    [CrashlyticsKit setObjectValue:@([blogService blogCountForAllAccounts]) forKey:WPCrashlyticsKeyNumberOfBlogs];
}

 - (void)clearCommonCrashlyticsParameters
{
    [CrashlyticsKit setUserName:nil];
    [CrashlyticsKit setObjectValue:nil forKey:WPCrashlyticsKeyLoggedIn];
    [CrashlyticsKit setObjectValue:nil forKey:WPCrashlyticsKeyConnectedToDotcom];
    [CrashlyticsKit setObjectValue:nil forKey:WPCrashlyticsKeyNumberOfBlogs];
}

#pragma mark - CrashlyticsDelegate

- (void)crashlyticsDidDetectReportForLastExecution:(CLSReport *)report completionHandler:(void (^)(BOOL submit))completionHandler
{
    DDLogMethod();

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger crashCount = [defaults integerForKey:@"crashCount"];
    crashCount += 1;
    [defaults setInteger:crashCount forKey:@"crashCount"];

    if (completionHandler) {
        //  Invoking the completionHandler with NO will cause the detected report to be deleted and not submitted to Crashlytics.
        BOOL shouldSubmitReportToCrashlytics = ![WPCrashlytics userHasOptedOut];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionHandler(shouldSubmitReportToCrashlytics);
        }];
    }
}

@end
