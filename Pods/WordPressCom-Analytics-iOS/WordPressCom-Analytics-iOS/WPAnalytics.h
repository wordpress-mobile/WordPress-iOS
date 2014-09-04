#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WPAnalyticsStat) {
    WPAnalyticsStatNoStat, // Since we can't have a nil enum we'll use this to act as the nil
    WPAnalyticsStatAddedSelfHostedSite,
    WPAnalyticsStatAddedSelfHostedSiteButJetpackNotConnectedToWPCom,
    WPAnalyticsStatApplicationClosed,
    WPAnalyticsStatApplicationOpened,
    WPAnalyticsStatCreatedAccount,
    WPAnalyticsStatEditorAddedPhotoViaLocalLibrary,
    WPAnalyticsStatEditorAddedPhotoViaWPMediaLibrary,
    WPAnalyticsStatEditorClosed,
    WPAnalyticsStatEditorCreatedPost,
    WPAnalyticsStatEditorDiscardedChanges,
    WPAnalyticsStatEditorPublishedPost,
    WPAnalyticsStatEditorSavedDraft,
    WPAnalyticsStatEditorScheduledPost,
    WPAnalyticsStatEditorUpdatedPost,
    WPAnalyticsStatNotificationApproved,
    WPAnalyticsStatNotificationUnapproved,
    WPAnalyticsStatNotificationFlaggedAsSpam,
    WPAnalyticsStatNotificationFollowAction,
    WPAnalyticsStatNotificationUnfollowAction,
    WPAnalyticsStatNotificationLiked,
    WPAnalyticsStatNotificationUnliked,
    WPAnalyticsStatNotificationRepliedTo,
    WPAnalyticsStatNotificationTrashed,
    WPAnalyticsStatNotificationsAccessed,
    WPAnalyticsStatNotificationsOpenedNotificationDetails,
    WPAnalyticsStatOpenedComments,
    WPAnalyticsStatOpenedMediaLibrary,
    WPAnalyticsStatOpenedPages,
    WPAnalyticsStatOpenedPosts,
    WPAnalyticsStatOpenedSettings,
    WPAnalyticsStatOpenedViewAdmin,
    WPAnalyticsStatOpenedViewSite,
    WPAnalyticsStatPerformedJetpackSignInFromStatsScreen,
    WPAnalyticsStatPublishedPostWithCategories,
    WPAnalyticsStatPublishedPostWithPhoto,
    WPAnalyticsStatPublishedPostWithTags,
    WPAnalyticsStatPublishedPostWithVideo,
    WPAnalyticsStatReaderAccessed,
    WPAnalyticsStatReaderCommentedOnArticle,
    WPAnalyticsStatReaderFollowedReaderTag,
    WPAnalyticsStatReaderFollowedSite,
    WPAnalyticsStatReaderInfiniteScroll,
    WPAnalyticsStatReaderLikedArticle,
    WPAnalyticsStatReaderLoadedFreshlyPressed,
    WPAnalyticsStatReaderLoadedTag,
    WPAnalyticsStatReaderOpenedArticle,
    WPAnalyticsStatReaderRebloggedArticle,
    WPAnalyticsStatReaderUnfollowedReaderTag,
    WPAnalyticsStatSelectedInstallJetpack,
    WPAnalyticsStatSelectedLearnMoreInConnectToJetpackScreen,
    WPAnalyticsStatSentItemToGooglePlus,
    WPAnalyticsStatSentItemToInstapaper,
    WPAnalyticsStatSentItemToPocket,
    WPAnalyticsStatSentItemToWordPress,
    WPAnalyticsStatSharedItem,
    WPAnalyticsStatSharedItemViaEmail,
    WPAnalyticsStatSharedItemViaFacebook,
    WPAnalyticsStatSharedItemViaSMS,
    WPAnalyticsStatSharedItemViaTwitter,
    WPAnalyticsStatSharedItemViaWeibo,
    WPAnalyticsStatSignedIn,
    WPAnalyticsStatSignedInToJetpack,
    WPAnalyticsStatSkippedConnectingToJetpack,
    WPAnalyticsStatStatsAccessed,
    WPAnalyticsStatStatsOpenedWebVersion,
    WPAnalyticsStatStatsTappedBarChart,
    WPAnalyticsStatStatsScrolledToBottom,
    WPAnalyticsStatThemesAccessedThemeBrowser,
    WPAnalyticsStatThemesChangedTheme,
};

@protocol WPAnalyticsTracker;
@interface WPAnalytics : NSObject

+ (void)registerTracker:(id<WPAnalyticsTracker>)tracker;
+ (void)clearTrackers;
+ (void)beginSession;
+ (void)refreshMetadata;
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
- (void)refreshMetadata;

@end
