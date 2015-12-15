#import "WPAppAnalytics.h"

#import "ContextManager.h"
#import "WPAnalyticsTrackerMixpanel.h"
#import "WPAnalyticsTrackerWPCom.h"
#import "WPAnalyticsTrackerAutomatticTracks.h"
#import "WPTabBarController.h"
#import "WordPressComApiCredentials.h"
#import "WordPressAppDelegate.h"
#import "Blog.h"

NSString * const WPAppAnalyticsDefaultsKeyUsageTracking = @"usage_tracking_enabled";
NSString * const WPAppAnalyticsKeyBlogID = @"blog_id";
NSString * const WPAppAnalyticsKeyPostID = @"post_id";
NSString * const WPAppAnalyticsKeyFeedID = @"feed_id";
NSString * const WPAppAnalyticsKeyFeedItemID = @"feed_item_id";
NSString * const WPAppAnalyticsKeyIsJetpack = @"is_jetpack";
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
    
    if ([WordPressComApiCredentials mixpanelAPIToken].length > 0) {
        [WPAnalytics registerTracker:[[WPAnalyticsTrackerMixpanel alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]]];
    }

    [WPAnalytics registerTracker:[[WPAnalyticsTrackerWPCom alloc] init]];
    [WPAnalytics registerTracker:[WPAnalyticsTrackerAutomatticTracks new]];

    if ([self isTrackingUsage]) {
        [self beginSession];
    }
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
    [self trackApplicationOpened];
}

- (void)applicationDidEnterBackground:(NSNotification*)notification
{
    [self trackApplicationClosed];
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

- (BOOL)isTrackingUsage
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:WPAppAnalyticsDefaultsKeyUsageTracking];
}

- (void)setTrackingUsage:(BOOL)trackingUsage
{
    if (trackingUsage != [self isTrackingUsage]) {
        [[NSUserDefaults standardUserDefaults] setBool:trackingUsage
                                                forKey:WPAppAnalyticsDefaultsKeyUsageTracking];
        
        if (trackingUsage) {
            [self beginSession];
        } else {
            [self endSession];
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
