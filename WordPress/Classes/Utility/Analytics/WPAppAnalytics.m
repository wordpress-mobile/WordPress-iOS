#import "WPAppAnalytics.h"

#import "ContextManager.h"
#import "WPAnalyticsTrackerMixpanel.h"
#import "WPAnalyticsTrackerWPCom.h"
#import "WPAnalyticsTrackerAutomatticTracks.h"
#import "WPTabBarController.h"
#import "WordPressComApiCredentials.h"

NSString* const WPAppAnalyticsDefaultsKeyUsageTracking = @"usage_tracking_enabled";
static NSString* const WPAppAnalyticsKeyLastVisibleScreen = @"last_visible_screen";
static NSString* const WPAppAnalyticsKeyTimeInApp = @"time_in_app";

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
