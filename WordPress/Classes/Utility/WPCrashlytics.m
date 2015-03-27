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
        [Crashlytics startWithAPIKey:apiKey];
        [[Crashlytics sharedInstance] setDelegate:self];
        
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
    [Crashlytics setUserName:defaultAccount.username];
    [Crashlytics setObjectValue:@(loggedIn) forKey:@"logged_in"];
    [Crashlytics setObjectValue:@(loggedIn) forKey:@"connected_to_dotcom"];
    [Crashlytics setObjectValue:@([blogService blogCountForAllAccounts]) forKey:@"number_of_blogs"];
}

#pragma mark - CrashlyticsDelegate

- (void)crashlytics:(Crashlytics *)crashlytics didDetectCrashDuringPreviousExecution:(id<CLSCrashReport>)crash
{
    DDLogMethod();
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger crashCount = [defaults integerForKey:@"crashCount"];
    crashCount += 1;
    [defaults setInteger:crashCount forKey:@"crashCount"];
    [defaults synchronize];
}


@end
