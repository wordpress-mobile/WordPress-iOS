#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const WPAppAnalyticsDefaultsUserOptedOut;
extern NSString * const WPAppAnalyticsKeyBlogID;
extern NSString * const WPAppAnalyticsKeyPostID;
extern NSString * const WPAppAnalyticsKeyPostAuthorID;
extern NSString * const WPAppAnalyticsKeyFeedID;
extern NSString * const WPAppAnalyticsKeyFeedItemID;
extern NSString * const WPAppAnalyticsKeyIsJetpack;
extern NSString * const WPAppAnalyticsKeyEditorSource;
extern NSString * const WPAppAnalyticsKeyCommentID;
extern NSString * const WPAppAnalyticsKeyLegacyQuickAction;
extern NSString * const WPAppAnalyticsKeyQuickAction;
extern NSString * const WPAppAnalyticsKeyFollowAction;
extern NSString * const WPAppAnalyticsKeySource;
extern NSString * const WPAppAnalyticsKeyPostType;
extern NSString * const WPAppAnalyticsKeyTapSource;
extern NSString * const WPAppAnalyticsKeyTabSource;
extern NSString * const WPAppAnalyticsKeyReplyingTo;
extern NSString * const WPAppAnalyticsKeySiteType;
extern NSString * const WPAppAnalyticsValueSiteTypeBlog;
extern NSString * const WPAppAnalyticsValueSiteTypeP2;

/**
 *  @class      WPAppAnalytics
 *  @brief      This is a container for the app-specific analytics logic.
 *  @details    WPAnalytics is a generic component.  This component acts as a container for all
 *              of the WPAnalytics code that's specific to WordPress, interfacing with WPAnalytics
 *              where appropiate.  This is mostly useful to remove such app-specific logic from
 *              our app delegate class.
 */
@interface WPAppAnalytics : NSObject

/**
 *  @brief      Timestamp of the app's opening time.
 */
@property (nonatomic, strong, readwrite, nullable) NSDate* applicationOpenedTime;

#pragma mark - Init

/**
 *  @brief      Default initializer.
 *
 *  @returns    The initialized object.
 */
- (instancetype)init;

#pragma mark - User Opt Out

/**
 *  @brief      Call this method to know if the user has opted out of tracking.
 *
 *  @returns    YES if the user has opted out, NO otherwise.
 */
+ (BOOL)userHasOptedOut;

/**
 *  @brief      Sets user opt out ON or OFF
 *
 *  @param      optedOut   The new status for user opt out.
 */
- (void)setUserHasOptedOut:(BOOL)optedOut;

#pragma mark - Internal

+ (NSError *)sanitizedErrorFromError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
