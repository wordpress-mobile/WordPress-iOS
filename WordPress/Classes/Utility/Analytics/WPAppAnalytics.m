@import WordPressDataObjC;
@import NSObject_SafeExpectations;

#import "WPAppAnalytics.h"
#import "WPAnalyticsTrackerWPCom.h"
#import "WPAnalyticsTrackerAutomatticTracks.h"
#import "WordPress-Swift.h"

NSString * const WPAppAnalyticsDefaultsUserOptedOut                 = @"tracks_opt_out";
NSString * const WPAppAnalyticsKeyBlogID                            = @"blog_id";
NSString * const WPAppAnalyticsKeyPostID                            = @"post_id";
NSString * const WPAppAnalyticsKeyPostAuthorID                      = @"post_author_id";
NSString * const WPAppAnalyticsKeyFeedID                            = @"feed_id";
NSString * const WPAppAnalyticsKeyFeedItemID                        = @"feed_item_id";
NSString * const WPAppAnalyticsKeyIsJetpack                         = @"is_jetpack";
NSString * const WPAppAnalyticsKeySubscriptionCount                 = @"subscription_count";
NSString * const WPAppAnalyticsKeyEditorSource                      = @"editor_source";
NSString * const WPAppAnalyticsKeyCommentID                         = @"comment_id";
NSString * const WPAppAnalyticsKeyLegacyQuickAction                 = @"is_quick_action";
NSString * const WPAppAnalyticsKeyQuickAction                       = @"quick_action";
NSString * const WPAppAnalyticsKeyFollowAction                      = @"follow_action";
NSString * const WPAppAnalyticsKeySource                            = @"source";
NSString * const WPAppAnalyticsKeyPostType                          = @"post_type";
NSString * const WPAppAnalyticsKeyTapSource                         = @"tap_source";
NSString * const WPAppAnalyticsKeyTabSource                         = @"tab_source";
NSString * const WPAppAnalyticsKeyReplyingTo                        = @"replying_to";
NSString * const WPAppAnalyticsKeySiteType                          = @"site_type";

NSString * const WPAppAnalyticsValueSiteTypeBlog                    = @"blog";
NSString * const WPAppAnalyticsValueSiteTypeP2                      = @"p2";

@implementation WPAppAnalytics

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self initializeAppTracking];
        [self startObservingNotifications];
    }
    
    return self;
}

#pragma mark - Init helpers

/**
 *  @brief      Initializes analytics tracking for WPiOS.
 */
- (void)initializeAppTracking
{
    [self initializeOptOutTracking];

    BOOL userHasOptedOut = [WPAppAnalytics userHasOptedOut];
    BOOL isUITesting = [[NSProcessInfo processInfo].arguments containsObject:@"-ui-testing"];
    if (!isUITesting && !userHasOptedOut) {
        [self registerTrackers];
        [self beginSession];
    }
}

- (void)registerTrackers
{
    [WPAnalytics registerTracker:[WPAnalyticsTrackerWPCom new]];
    [WPAnalytics registerTracker:[WPAnalyticsTrackerAutomatticTracks new]];
}

- (void)clearTrackers
{
    [WPAnalytics clearQueuedEvents];
    [WPAnalytics clearTrackers];
}

#pragma mark - Notifications

- (void)startObservingNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountSettingsDidChange:)
                                                 name:NSNotification.AccountSettingsChanged
                                               object:nil];
}

#pragma mark - Notifications

- (void)accountSettingsDidChange:(NSNotification*)notification
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    WPAccount *defaultAccount = [WPAccount lookupDefaultWordPressComAccountInContext:context];
    if (!defaultAccount.settings) {
        return;
    }

    [self setUserHasOptedOut:defaultAccount.settings.tracksOptOut];
}

#pragma mark - App Tracking

/**
 * @brief   Sanitize an NSError so we're not tracking unnecessary or usless information.
 */
+ (NSError * _Nonnull)sanitizedErrorFromError:(NSError * _Nonnull)error
{
    // WordPressOrgXMLRPCApi will, in certain circumstances, store an entire HTTP response in this key.
    // The information is generally unhelpful.
    // We'll truncate the string to avoid tracking garbage but still allow for some context.
    NSString *dataString = [[error userInfo] stringForKey:WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyDataString];
    NSUInteger threshold = 100;
    if ([dataString length] > threshold) {
        NSMutableDictionary *dict = [[error userInfo] mutableCopy];
        [dict setObject:[dataString substringToIndex:threshold] forKey:WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyDataString];
        return [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:dict];
    }
    return error;
}

#pragma mark - Tracks Opt Out

- (void)initializeOptOutTracking {
    if ([WPAppAnalytics userHasOptedOutIsSet]) {
        // We've already configured the opt out setting
        return;
    }
    [self setUserHasOptedOutValue:NO];
}

+ (BOOL)userHasOptedOutIsSet {
    return [[UserPersistentStoreFactory userDefaultsInstance] objectForKey:WPAppAnalyticsDefaultsUserOptedOut] != nil;
}

+ (BOOL)userHasOptedOut {
    return [[UserPersistentStoreFactory userDefaultsInstance] boolForKey:WPAppAnalyticsDefaultsUserOptedOut];
}

/// This method just sets the user defaults value for UserOptedOut, and doesn't
/// do any additional configuration of sessions or trackers.
- (void)setUserHasOptedOutValue:(BOOL)optedOut
{
    [[UserPersistentStoreFactory userDefaultsInstance] setBool:optedOut forKey:WPAppAnalyticsDefaultsUserOptedOut];
}

- (void)setUserHasOptedOut:(BOOL)optedOut
{
    if ([WPAppAnalytics userHasOptedOutIsSet]) {
        BOOL currentValue = [WPAppAnalytics userHasOptedOut];
        if (currentValue == optedOut) {
            return;
        }
    }

    [self setUserHasOptedOutValue:optedOut];

    if (optedOut) {
        [self endSession];
        [self clearTrackers];
    } else {
        [self registerTrackers];
        [self beginSession];
    }
}

#pragma mark - Session

- (void)beginSession
{
    DDLogInfo(@"WPAnalytics session started");
    
    [WPAnalytics beginSession];
}

- (void)endSession
{
    DDLogInfo(@"WPAnalytics session stopped");
    
    [WPAnalytics endSession];
}

@end
