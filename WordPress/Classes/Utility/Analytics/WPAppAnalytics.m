#import "WPAppAnalytics.h"

#import "ContextManager.h"
#import "WPAnalyticsTrackerWPCom.h"
#import "WPAnalyticsTrackerAutomatticTracks.h"
#import "WPTabBarController.h"
#import "ApiCredentials.h"
#import "WordPressAppDelegate.h"
#import "Blog.h"
#import "AbstractPost.h"
#import "WordPress-Swift.h"

NSString * const WPAppAnalyticsDefaultsKeyUsageTracking = @"usage_tracking_enabled";
NSString * const WPAppAnalyticsKeyBlogID = @"blog_id";
NSString * const WPAppAnalyticsKeyPostID = @"post_id";
NSString * const WPAppAnalyticsKeyFeedID = @"feed_id";
NSString * const WPAppAnalyticsKeyFeedItemID = @"feed_item_id";
NSString * const WPAppAnalyticsKeyIsJetpack = @"is_jetpack";
NSString * const WPAppAnalyticsKeySessionCount = @"session_count";
NSString * const WPAppAnalyticsKeyEditorSource = @"editor_source";
static NSString * const WPAppAnalyticsKeyLastVisibleScreen = @"last_visible_screen";
static NSString * const WPAppAnalyticsKeyTimeInApp = @"time_in_app";

@interface WPAppAnalytics ()

/**
 *  @brief      Timestamp of the app's opening time.
 */
@property (nonatomic, strong, readwrite) NSDate* applicationOpenedTime;

/**
 *  @brief      If set, this block will be called whenever this object needs to know what the last
 *              visible screen was, for tracking purposes.
 */
@property (nonatomic, copy, readwrite) WPAppAnalyticsLastVisibleScreenCallback lastVisibleScreenCallback;
@end

@implementation WPAppAnalytics

#pragma mark - Dealloc

- (void)dealloc
{
    [self stopObservingNotifications];
}

#pragma mark - Init

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithLastVisibleScreenBlock:(WPAppAnalyticsLastVisibleScreenCallback)lastVisibleScreenCallback
{
    NSParameterAssert(lastVisibleScreenCallback);
    
    self = [super init];
    
    if (self) {
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
    [self initializeUsageTrackingIfNecessary];

    BOOL trackingEnabled = [WPAppAnalytics isTrackingUsage];
    if (trackingEnabled) {
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
    [WPAnalytics clearTrackers];
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
}

- (void)stopObservingNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    [[NSUserDefaults standardUserDefaults] synchronize];

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
    
    [WPAnalytics track:WPAnalyticsStatApplicationClosed withProperties:analyticsProperties];
    [WPAnalytics endSession];
}

/**
 *  @brief      Tracks that the application has been opened.
 */
- (void)trackApplicationOpened
{
    self.applicationOpenedTime = [NSDate date];
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
    [WPAppAnalytics track:stat withProperties:nil withBlogID:blogID];
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


#pragma mark - Usage tracking initialization

- (void)initializeUsageTrackingIfNecessary
{
    if (![self isUsageTrackingInitialized]) {
        [self setTrackingUsage:YES];
        [NSUserDefaults resetStandardUserDefaults];
    }
}

- (BOOL)isUsageTrackingInitialized
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:WPAppAnalyticsDefaultsKeyUsageTracking] != nil;
}

#pragma mark - Usage tracking

+ (BOOL)isTrackingUsage
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:WPAppAnalyticsDefaultsKeyUsageTracking];
}

- (void)setTrackingUsage:(BOOL)trackingUsage
{
    if (trackingUsage != [WPAppAnalytics isTrackingUsage]) {
        [[NSUserDefaults standardUserDefaults] setBool:trackingUsage
                                                forKey:WPAppAnalyticsDefaultsKeyUsageTracking];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (trackingUsage) {
            [self registerTrackers];
            [self beginSession];
        } else {
            [self endSession];
            [self clearTrackers];
        }
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
