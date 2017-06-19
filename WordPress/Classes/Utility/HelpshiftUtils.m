#import "HelpshiftUtils.h"

#import "HelpshiftCore.h"
#import "HelpshiftSupport.h"

#import "AccountService.h"
#import "ApiCredentials.h"
#import "Blog.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "WPAccount.h"

NSString *const UserDefaultsHelpshiftEnabled = @"wp_helpshift_enabled";
NSString *const UserDefaultsHelpshiftWasUsed = @"wp_helpshift_used";
NSString *const HelpshiftUnreadCountUpdatedNotification = @"HelpshiftUnreadCountUpdatedNotification";
// This delay is required to give some time to Mixpanel to update the remote variable
CGFloat const HelpshiftFlagCheckDelay = 2.0;

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
    if ([[ApiCredentials helpshiftAPIKey] length] == 0) {
        [[self sharedInstance] disableHelpshift];
        return;
    }
    [HelpshiftCore initializeWithProvider:[HelpshiftSupport sharedInstance]];
    [[HelpshiftSupport sharedInstance] setDelegate:[HelpshiftUtils sharedInstance]];
    [HelpshiftCore installForApiKey:[ApiCredentials helpshiftAPIKey]
                         domainName:[ApiCredentials helpshiftDomainName]
                              appID:[ApiCredentials helpshiftAppId]];
    
    // Lets enable Helpshift by default on startup because the time to get data back from Mixpanel
    // can result in users who first launch the app being unable to contact us.
    [[HelpshiftUtils sharedInstance] enableHelpshift];
    
    
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

    // TODO: Replace Mixpanel tweak to enable/disable Helpshift
    [self enableHelpshift];
}

- (void)enableHelpshift
{
    DDLogInfo(@"Helpshift Enabled");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:UserDefaultsHelpshiftEnabled];
    [defaults synchronize];
    
    // if the Helpshift is enabled we want to refresh unread count, since the check happens with a delay
    [HelpshiftUtils refreshUnreadNotificationCount];
}

- (void)disableHelpshiftIfNotAlreadyUsed
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:UserDefaultsHelpshiftWasUsed]) {
        return;
    }
    
    [self disableHelpshift];
}

- (void)disableHelpshift
{
    DDLogInfo(@"Helpshift Disabled");

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:UserDefaultsHelpshiftEnabled];
    [defaults synchronize];
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

+ (NSArray<NSString *> *)planTagsForAccount:(WPAccount *)account
{
    NSMutableSet<NSString *> *tags = [NSMutableSet set];
    for (Blog *blog in account.blogs) {
        if (blog.planID == nil) {
            continue;
        }
        NSString *tag = [NSString stringWithFormat:@"plan:%@", blog.planID];
        [tags addObject:tag];
    }

    return [tags allObjects];
}

+ (NSDictionary<NSString *, NSObject *> *)helpshiftMetadataWithTags:(NSArray<NSString *> *)extraTags;
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    NSString *isWPCom = (defaultAccount != nil) ? @"Yes" : @"No";
    NSMutableDictionary *metaData = [NSMutableDictionary dictionaryWithDictionary:@{ @"isWPCom" : isWPCom }];
    NSMutableArray *tags = [NSMutableArray arrayWithArray:extraTags];
    
    NSArray *allBlogs = [blogService blogsForAllAccounts];
    for (int i = 0; i < allBlogs.count; i++) {
        Blog *blog = allBlogs[i];

        NSDictionary *blogData = @{[NSString stringWithFormat:@"blog-%i", i+1]: [blog logDescription]};

        [metaData addEntriesFromDictionary:blogData];

        if (defaultAccount) {
            [metaData addEntriesFromDictionary:@{@"WPCom Username": defaultAccount.username}];
            NSArray *planTags = [HelpshiftUtils planTagsForAccount:defaultAccount];
            if (planTags) {
                [tags addObjectsFromArray:planTags];
            }
        }
    }
    
    [metaData setObject:tags forKey:HelpshiftSupportTagsKey];

    return [metaData copy];
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
    if ([newMessage isEqualToString:HelpshiftSupportUserAcceptedTheSolution]) {
        [WPAnalytics track:WPAnalyticsStatSupportUserAcceptedTheSolution];
    } else if ([newMessage isEqualToString:HelpshiftSupportUserRejectedTheSolution]) {
        [WPAnalytics track:WPAnalyticsStatSupportUserRejectedTheSolution];
    } else if ([newMessage isEqualToString:HelpshiftSupportUserSentScreenShot]) {
        [WPAnalytics track:WPAnalyticsStatSupportUserSentScreenshot];
    } else if ([newMessage isEqualToString:HelpshiftSupportUserReviewedTheApp]) {
        [WPAnalytics track:WPAnalyticsStatSupportUserReviewedTheApp];
    } else {
        [WPAnalytics track:WPAnalyticsStatSupportUserRepliedToHelpshift];
    }
}

@end
