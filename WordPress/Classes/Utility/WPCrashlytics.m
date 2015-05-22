#import "WPCrashlytics.h"

#import <Crashlytics/Crashlytics.h>
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "WPAccount.h"

@interface WPCrashlytics () <CrashlyticsDelegate>
@end

@implementation WPCrashlytics

#pragma mark - Dealloc

- (void)dealloc
{
    [self stopObservingNotifications];
}

#pragma mark - Initialization

- (instancetype)initWithAPIKey:(NSString *)apiKey
{
    NSParameterAssert(apiKey);
    
    self = [super init];
    
    if (self) {
        [[Crashlytics sharedInstance] setDelegate:self];
        [Fabric with:@[CrashlyticsKit]];
        
        [self setCommonCrashlyticsParameters];
        [self startObservingNotifications];
    }
    
    return self;
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

- (void)stopObservingNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter removeObserver:self];
}

- (void)handleDefaultAccountChangedNotification:(NSNotification *)notification
{
    [self setCommonCrashlyticsParameters];
}

#pragma mark - Common crashlytics parameters

- (void)setCommonCrashlyticsParameters
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    BOOL loggedIn = defaultAccount != nil;
    [[Crashlytics sharedInstance] setUserName:defaultAccount.username];
    [[Crashlytics sharedInstance] setObjectValue:@(loggedIn) forKey:@"logged_in"];
    [[Crashlytics sharedInstance] setObjectValue:@(loggedIn) forKey:@"connected_to_dotcom"];
    [[Crashlytics sharedInstance] setObjectValue:@([blogService blogCountForAllAccounts]) forKey:@"number_of_blogs"];
}

#pragma mark - CrashlyticsDelegate

- (void)crashlyticsDidDetectReportForLastExecution:(CLSReport *)report completionHandler:(void (^)(BOOL submit))completionHandler
{
    DDLogMethod();
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger crashCount = [defaults integerForKey:@"crashCount"];
    crashCount += 1;
    [defaults setInteger:crashCount forKey:@"crashCount"];
    [defaults synchronize];
    if (completionHandler) {
        completionHandler(YES);
    }
}


@end
