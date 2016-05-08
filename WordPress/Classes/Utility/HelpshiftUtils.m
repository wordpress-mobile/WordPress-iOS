#import "HelpShiftUtils.h"
#import <Mixpanel/MPTweakInline.h>
#import "WordPressComApiCredentials.h"
#import <Helpshift/HelpshiftCore.h>
#import <Helpshift/HelpshiftSupport.h>

NSString *const UserDefaultsHelpshiftEnabled = @"wp_helpshift_enabled";
NSString *const UserDefaultsHelpshiftWasUsed = @"wp_helpshift_used";
NSString *const HelpshiftUnreadCountUpdatedNotification = @"HelpshiftUnreadCountUpdatedNotification";
// This delay is required to give some time to Mixpanel to update the remote variable
CGFloat const HelpshiftFlagCheckDelay = 10.0;

@interface HelpshiftUtils () <HelpshiftSupportDelegate>

@property (nonatomic, assign) NSInteger unreadNotificationCount;

@end

@implementation HelpshiftUtils

#pragma mark - Class Methods

+ (id)sharedInstance
{
    static HelpshiftUtils *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

+ (void)setup
{
    [HelpshiftCore initializeWithProvider:[HelpshiftSupport sharedInstance]];
    [[HelpshiftSupport sharedInstance] setDelegate:[HelpshiftUtils sharedInstance]];
    [HelpshiftCore installForApiKey:[WordPressComApiCredentials helpshiftAPIKey] domainName:[WordPressComApiCredentials helpshiftDomainName] appID:[WordPressComApiCredentials helpshiftAppId]];

    // We want to make sure Mixpanel updates the remote variable before we check for the flag
    [[HelpshiftUtils sharedInstance] performSelector:@selector(checkIfHelpshiftShouldBeEnabled)
                                          withObject:nil
                                          afterDelay:HelpshiftFlagCheckDelay];
}

- (void)checkIfHelpshiftShouldBeEnabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{UserDefaultsHelpshiftEnabled:@NO}];

    BOOL userHasUsedHelpshift = [defaults boolForKey:UserDefaultsHelpshiftWasUsed];

    if (userHasUsedHelpshift) {
        [defaults setBool:YES forKey:UserDefaultsHelpshiftEnabled];
        [defaults synchronize];
        return;
    }

    if (MPTweakValue(@"Helpshift Enabled", NO)) {
        DDLogInfo(@"Helpshift Enabled");

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:UserDefaultsHelpshiftEnabled];
        [defaults synchronize];

        // if the Helpshift is enabled we want to refresh unread count, since the check happens with a delay
        [HelpshiftUtils refreshUnreadNotificationCount];
    } else {
        DDLogInfo(@"Helpshift Disabled");

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO forKey:UserDefaultsHelpshiftEnabled];
        [defaults synchronize];
    }
}

+ (BOOL)isHelpshiftEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsHelpshiftEnabled];
}

+ (NSInteger)unreadNotificationCount
{
    return [[HelpshiftUtils sharedInstance] unreadNotificationCount];
}

+ (void)refreshUnreadNotificationCount
{
    [HelpshiftSupport getNotificationCountFromRemote:YES];
}

#pragma mark - HelpshiftSupport Delegate

- (void)didReceiveInAppNotificationWithMessageCount:(NSInteger)count
{
    if (count > 0) {
        [WPAnalytics track:WPAnalyticsStatSupportReceivedResponseFromSupport];
    }
}

- (void)didReceiveNotificationCount:(NSInteger)count
{
    self.unreadNotificationCount = count;

    // updating unread count should trigger UI updates, that's why the notification is sent in main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:HelpshiftUnreadCountUpdatedNotification object:nil];
    });
}

- (void)userRepliedToConversationWithMessage:(NSString *)newMessage
{
    [WPAnalytics track:WPAnalyticsStatSupportSentReplyToSupportMessage];
}

@end
