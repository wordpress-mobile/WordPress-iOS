#import <Foundation/Foundation.h>

@class Blog;

typedef NSString*(^WPAppAnalyticsLastVisibleScreenCallback)();

extern NSString * const WPAppAnalyticsDefaultsKeyUsageTracking;
extern NSString * const WPAppAnalyticsKeyBlogID;
extern NSString * const WPAppAnalyticsKeyPostID;
extern NSString * const WPAppAnalyticsKeyFeedID;
extern NSString * const WPAppAnalyticsKeyFeedItemID;
extern NSString * const WPAppAnalyticsKeyIsJetpack;

/**
 *  @class      WPAppAnalytics
 *  @brief      This is a container for the app-specific analytics logic.
 *  @details    WPAnalytics is a generic component.  This component acts as a container for all
 *              of the WPAnalytics code that's specific to WordPress, interfacing with WPAnalytics
 *              where appropiate.  This is mostly useful to remove such app-specific logic from
 *              our app delegate class.
 */
@interface WPAppAnalytics : NSObject

#pragma mark - Init

/**
 *  @brief      Default initializer.
 *
 *  @param      lastVisibleScreenCallback       This block will be executed whenever this object
 *                                              needs to know the last visible screen for tracking
 *                                              purposes.
 *
 *  @returns    The initialized object.
 */
- (instancetype)initWithLastVisibleScreenBlock:(WPAppAnalyticsLastVisibleScreenCallback)lastVisibleScreenCallback;

#pragma mark - Usage tracking

/**
 *  @brief      Call this method to know if usage is being tracked.
 *
 *  @returns    YES if usage is being tracked, NO otherwise.
 */
- (BOOL)isTrackingUsage;

/**
 *  @brief      Sets usage tracking ON or OFF
 *
 *  @param      trackingUsage   The new status for usage tracking.
 */
- (void)setTrackingUsage:(BOOL)trackingUsage;

/**
 *  @brief      Tracks stats with the blog details when available
 */
+ (void)track:(WPAnalyticsStat)stat withBlog:(Blog *)blog;

/**
 *  @brief      Tracks stats with the blog_id when available
 */
+ (void)track:(WPAnalyticsStat)stat withBlogID:(NSNumber*)blogID;

/**
 *  @brief      Tracks stats with the blog details when available
 */
+ (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties withBlog:(Blog *)blog;

/**
 *  @brief      Tracks stats with the blog_id when available
 */
+ (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties withBlogID:(NSNumber*)blogID;


/**
 *  @brief      Pass-through methods to WPAnalytics
 */
+ (void)track:(WPAnalyticsStat)stat;

+ (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties;

@end
