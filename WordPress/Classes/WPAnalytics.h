#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WPAnalyticsStat) {
    WPStatNoStat, // Since we can't have a nil enum we'll use this to act as the nil
    WPStatApplicationOpened,
    WPStatApplicationClosed,
    WPStatThemesAccessedThemeBrowser,
    WPStatThemesChangedTheme,
    WPStatReaderAccessed,
    WPStatReaderOpenedArticle,
    WPStatReaderLikedArticle,
    WPStatReaderRebloggedArticle,
    WPStatReaderInfiniteScroll,
    WPStatReaderFollowedReaderTag,
    WPStatReaderUnfollowedReaderTag,
    WPStatReaderLoadedTag,
    WPStatReaderLoadedFreshlyPressed,
    WPStatReaderCommentedOnArticle,
    WPStatStatsAccessed,
    WPStatEditorCreatedPost,
    WPStatEditorAddedPhotoViaLocalLibrary,
    WPStatEditorAddedPhotoViaWPMediaLibrary,
    WPStatEditorUpdatedPost,
    WPStatEditorPublishedPost,
    WPStatPublishedPostWithPhoto,
    WPStatPublishedPostWithVideo,
    WPStatPublishedPostWithCategories,
    WPStatPublishedPostWithTags,
    WPStatNotificationsAccessed,
    WPStatNotificationsOpenedNotificationDetails,
    WPStatOpenedPosts,
    WPStatOpenedPages,
    WPStatOpenedComments,
    WPStatOpenedViewSite,
    WPStatOpenedViewAdmin,
    WPStatOpenedMediaLibrary,
    WPStatOpenedSettings,
    WPStatCreatedAccount,
    WPStatSharedItem,
    WPStatSharedItemViaEmail,
    WPStatSharedItemViaSMS,
    WPStatSharedItemViaTwitter,
    WPStatSharedItemViaFacebook,
    WPStatSharedItemViaWeibo,
    WPStatSentItemToInstapaper,
    WPStatSentItemToPocket,
    WPStatSentItemToGooglePlus,
    WPStatNotificationPerformedAction,
    WPStatNotificationRepliedTo,
    WPStatNotificationApproved,
    WPStatNotificationTrashed,
    WPStatNotificationFlaggedAsSpam,
};

@protocol WPAnalyticsTracker;
@interface WPAnalytics : NSObject

+ (void)registerTracker:(id<WPAnalyticsTracker>)tracker;
+ (void)beginSession;
+ (void)track:(WPAnalyticsStat)stat;
+ (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties;
+ (void)endSession;

@end

@protocol WPAnalyticsTracker <NSObject>

- (void)track:(WPAnalyticsStat)stat;
- (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties;

@optional
- (void)beginSession;
- (void)endSession;

@end
