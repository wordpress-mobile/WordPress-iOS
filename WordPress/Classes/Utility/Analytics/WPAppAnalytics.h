#import <Foundation/Foundation.h>

typedef NSString*(^WPAppAnalyticsLastVisibleScreenCallback)();

extern NSString* const WPAppAnalyticsDefaultsKeyUsageTracking;

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

@end
