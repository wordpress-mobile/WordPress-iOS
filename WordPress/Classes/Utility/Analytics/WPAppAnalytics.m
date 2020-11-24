#import "WPAppAnalytics.h"

#import "ContextManager.h"
#import "WPAnalyticsTrackerWPCom.h"
#import "WPAnalyticsTrackerAutomatticTracks.h"
#import "WPTabBarController.h"
#import "ApiCredentials.h"
#import "AccountService.h"
#import "BlogService.h"
#import "Blog.h"
#import "AbstractPost.h"
#import "WordPress-Swift.h"

NSString * const WPAppAnalyticsDefaultsUserOptedOut                 = @"tracks_opt_out";
NSString * const WPAppAnalyticsDefaultsKeyUsageTracking_deprecated  = @"usage_tracking_enabled";
NSString * const WPAppAnalyticsKeyBlogID                            = @"blog_id";
NSString * const WPAppAnalyticsKeyPostID                            = @"post_id";
NSString * const WPAppAnalyticsKeyFeedID                            = @"feed_id";
NSString * const WPAppAnalyticsKeyFeedItemID                        = @"feed_item_id";
NSString * const WPAppAnalyticsKeyIsJetpack                         = @"is_jetpack";
NSString * const WPAppAnalyticsKeySessionCount                      = @"session_count";
NSString * const WPAppAnalyticsKeyEditorSource                      = @"editor_source";
NSString * const WPAppAnalyticsKeyCommentID                         = @"comment_id";
NSString * const WPAppAnalyticsKeyLegacyQuickAction                 = @"is_quick_action";
NSString * const WPAppAnalyticsKeyQuickAction                       = @"quick_action";
NSString * const WPAppAnalyticsKeyFollowAction                      = @"follow_action";
NSString * const WPAppAnalyticsKeySource                            = @"source";
NSString * const WPAppAnalyticsKeyPostType                          = @"post_type";
NSString * const WPAppAnalyticsKeyTapSource                         = @"tap_source";
NSString * const WPAppAnalyticsKeyReplyingTo                        = @"replying_to";
NSString * const WPAppAnalyticsKeySiteType                          = @"site_type";

NSString * const WPAppAnalyticsKeyHasGutenbergBlocks                = @"has_gutenberg_blocks";
static NSString * const WPAppAnalyticsKeyLastVisibleScreen          = @"last_visible_screen";
static NSString * const WPAppAnalyticsKeyTimeInApp                  = @"time_in_app";

NSString * const WPAppAnalyticsValueSiteTypeBlog                    = @"blog";
NSString * const WPAppAnalyticsValueSiteTypeP2                      = @"p2";


@interface WPAppAnalytics ()

/**
 *  @brief      Timestamp of the app's opening time.
 */
@property (nonatomic, strong, readwrite) NSDate* applicationOpenedTime;

@property (nonatomic, strong, readwrite) AccountService *accountService;

/**
 *  @brief      If set, this block will be called whenever this object needs to know what the last
 *              visible screen was, for tracking purposes.
 */
@property (nonatomic, copy, readwrite) WPAppAnalyticsLastVisibleScreenCallback lastVisibleScreenCallback;
@end

@implementation WPAppAnalytics

#pragma mark - Init

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithAccountService:(AccountService *)accountService
                lastVisibleScreenBlock:(WPAppAnalyticsLastVisibleScreenCallback)lastVisibleScreenCallback
{
    NSParameterAssert(accountService);
    NSParameterAssert(lastVisibleScreenCallback);
    
    self = [super init];
    
    if (self) {
        _accountService = accountService;
        _lastVisibleScreenCallback = lastVisibleScreenCallback;

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
    if (!userHasOptedOut) {
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

+ (NSString *)siteTypeForBlogWithID:(NSNumber *)blogID
{
    BlogService *service = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    Blog *blog = [service blogByBlogId:blogID];
    return [blog isWPForTeams] ? WPAppAnalyticsValueSiteTypeP2 : WPAppAnalyticsValueSiteTypeBlog;
}

#pragma mark - Notifications

- (void)startObservingNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountSettingsDidChange:)
                                                 name:NSNotification.AccountSettingsChanged
                                               object:nil];
}

#pragma mark - Notifications

- (void)applicationDidBecomeActive:(NSNotification*)notification
{
    [self incrementSessionCount];
    [self trackApplicationOpened];
    [SearchAdsAttribution.instance requestDetails];
}

- (void)applicationDidEnterBackground:(NSNotification*)notification
{
    [self trackApplicationClosed];
}

- (void)accountSettingsDidChange:(NSNotification*)notification
{
    WPAccount *defaultAccount = [self.accountService defaultWordPressComAccount];
    if (!defaultAccount.settings) {
        return;
    }

    [self setUserHasOptedOut:defaultAccount.settings.tracksOptOut];
}

#pragma mark - Session

+ (NSInteger)sessionCount
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:WPAppAnalyticsKeySessionCount];
}

- (NSInteger)incrementSessionCount
{
    NSInteger sessionCount = [[self class] sessionCount];
    sessionCount++;

    if (sessionCount == 1) {
        [WPAnalytics track:WPAnalyticsStatAppInstalled];
    }

    [[NSUserDefaults standardUserDefaults] setInteger:sessionCount forKey:WPAppAnalyticsKeySessionCount];

    return sessionCount;
}

#pragma mark - App Tracking

/**
 *  @brief      Tracks that the application has been closed.
 */
- (void)trackApplicationClosed
{
    NSMutableDictionary *analyticsProperties = [NSMutableDictionary new];
    
    analyticsProperties[WPAppAnalyticsKeyLastVisibleScreen] = self.lastVisibleScreenCallback();
    
    if (self.applicationOpenedTime != nil) {
        NSDate *applicationClosedTime = [NSDate date];
        NSTimeInterval timeInApp = round([applicationClosedTime timeIntervalSinceDate:self.applicationOpenedTime]);
        analyticsProperties[WPAppAnalyticsKeyTimeInApp] = @(timeInApp);
        self.applicationOpenedTime = nil;
    }

    [[ReaderTracker shared] stopAll];
    [analyticsProperties addEntriesFromDictionary: [[ReaderTracker shared] data]];
    
    [WPAnalytics track:WPAnalyticsStatApplicationClosed withProperties:analyticsProperties];
    [WPAnalytics endSession];
    [[ReaderTracker shared] reset];
}

/**
 *  @brief      Tracks that the application has been opened.
 */
- (void)trackApplicationOpened
{
    // UIApplicationDidBecomeActiveNotification will be dispatched if the user
    // returns from a system overlay (like notification center) or when multi
    // tasking on the iPad and adjusting the split screen divider. This happens
    // without previously dispatching UIApplicationDidEnterBackgroundNotification.
    // We don't want to track application opened in thise cases so check for a
    // nil applicationOpenedTime first.
    if (self.applicationOpenedTime != nil) {
        return;
    }
    self.applicationOpenedTime = [NSDate date];
    
    // This stat is part of a funnel that provides critical information.  Before
    // making ANY modification to this stat please refer to: p4qSXL-35X-p2
    [WPAnalytics track:WPAnalyticsStatApplicationOpened];
}


/**
 *  @brief      Tracks stats with the blog details when available
 */
+ (void)track:(WPAnalyticsStat)stat withBlog:(Blog *)blog {
    [WPAppAnalytics track:stat withBlogID:blog.dotComID];
}

/**
 *  @brief      Tracks stats with the blog_id when available
 */
+ (void)track:(WPAnalyticsStat)stat withBlogID:(NSNumber *)blogID {
    if (NSThread.isMainThread) {
        [WPAppAnalytics track:stat withProperties:nil withBlogID:blogID];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [WPAppAnalytics track:stat withProperties:nil withBlogID:blogID];
        });
    }
}

/**
 *  @brief      Tracks stats with the blog details when available
 */
+ (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties withBlog:(Blog *)blog {
    [WPAppAnalytics track:stat withProperties:properties withBlogID:blog.dotComID];
}

/**
 *  @brief      Tracks stats with the blog_id when available
 */
+ (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties withBlogID:(NSNumber *)blogID {
    NSMutableDictionary *mutableProperties;
    if (properties) {
        mutableProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
    } else {
        mutableProperties = [NSMutableDictionary new];
    }
    
    if (blogID) {
        [mutableProperties setObject:blogID forKey:WPAppAnalyticsKeyBlogID];

        NSString *siteType = [self siteTypeForBlogWithID:blogID];
        [mutableProperties setObject:siteType forKey:WPAppAnalyticsKeySiteType];
    }
    
    if ([mutableProperties count] > 0) {
        [WPAppAnalytics track:stat withProperties:mutableProperties];
    } else {
        [WPAppAnalytics track:stat];
    }
}

+ (void)track:(WPAnalyticsStat)stat withPost:(AbstractPost *)postOrPage {
    [WPAppAnalytics track:stat withProperties:nil withPost:postOrPage];
}

+ (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties withPost:(AbstractPost *)postOrPage {
    NSMutableDictionary *mutableProperties;
    if (properties) {
        mutableProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
    } else {
        mutableProperties = [NSMutableDictionary new];
    }

    if (postOrPage.postID.integerValue > 0) {
        mutableProperties[WPAppAnalyticsKeyPostID] = postOrPage.postID;
    }
    mutableProperties[WPAppAnalyticsKeyHasGutenbergBlocks] = @([postOrPage containsGutenbergBlocks]);

    [WPAppAnalytics track:stat withProperties:mutableProperties withBlog:postOrPage.blog];
}


+ (void)trackTrainTracksInteraction:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    NSMutableDictionary *mutableProperties;
    if (properties) {
        mutableProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
    } else {
        mutableProperties = [NSMutableDictionary new];
    }
    // TrainTracks are specific to the AutomatticTracks tracker.
    // The action property should be the event string for the stat.
    // Other trackers should ignore `WPAnalyticsStatTrainTracksInteract`
    NSString *eventName = [WPAnalyticsTrackerAutomatticTracks eventNameForStat:stat];
    [mutableProperties setObject:eventName forKey:@"action"];

    [self track:WPAnalyticsStatTrainTracksInteract withProperties:mutableProperties];
}

/**
 *  @brief      Pass-through method to [WPAnalytics track:stat]. Use this method instead of calling WPAnalytics directly.
 */
+ (void)track:(WPAnalyticsStat)stat {
    [WPAnalytics track:stat];
}

/**
 *  @brief      Pass-through method to WPAnalytics. Use this method instead of calling WPAnalytics directly.
 */
+ (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties {
    [WPAnalytics track:stat withProperties:properties];
}

+ (void)track:(WPAnalyticsStat)stat error:(NSError * _Nonnull)error {
    NSError *err = [self sanitizedErrorFromError:error];
    NSDictionary *properties = @{
                                 @"error_code": [@(err.code) stringValue],
                                 @"error_domain": err.domain,
                                 @"error_description": err.description
    };
    [self track:stat withProperties: properties];
}

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

#pragma mark - Usage tracking

+ (BOOL)isTrackingUsage
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:WPAppAnalyticsDefaultsKeyUsageTracking_deprecated];
}

- (void)setTrackingUsage:(BOOL)trackingUsage
{
    if (trackingUsage != [WPAppAnalytics isTrackingUsage]) {
        [[NSUserDefaults standardUserDefaults] setBool:trackingUsage
                                                forKey:WPAppAnalyticsDefaultsKeyUsageTracking_deprecated];
    }
}

#pragma mark - Tracks Opt Out

- (void)initializeOptOutTracking {
    if ([WPAppAnalytics userHasOptedOutIsSet]) {
        // We've already configured the opt out setting
        return;
    }

    if ([[NSUserDefaults standardUserDefaults] objectForKey:WPAppAnalyticsDefaultsKeyUsageTracking_deprecated] == nil) {
        [self setUserHasOptedOutValue:NO];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:WPAppAnalyticsDefaultsKeyUsageTracking_deprecated] == NO) {
        // If the user has already explicitly disabled tracking,
        // then we should mirror that to the new setting
        [self setUserHasOptedOutValue:YES];
    } else {
        [self setUserHasOptedOutValue:NO];
    }
}

+ (BOOL)userHasOptedOutIsSet {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WPAppAnalyticsDefaultsUserOptedOut] != nil;
}

+ (BOOL)userHasOptedOut {
    return [[NSUserDefaults standardUserDefaults] boolForKey:WPAppAnalyticsDefaultsUserOptedOut];
}

/// This method just sets the user defaults value for UserOptedOut, and doesn't
/// do any additional configuration of sessions or trackers.
- (void)setUserHasOptedOutValue:(BOOL)optedOut
{
    [[NSUserDefaults standardUserDefaults] setBool:optedOut forKey:WPAppAnalyticsDefaultsUserOptedOut];
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
