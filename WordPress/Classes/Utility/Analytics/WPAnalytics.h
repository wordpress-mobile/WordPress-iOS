#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WPAnalyticsStat) {
    WPAnalyticsStatNoStat, // Since we can't have a nil enum we'll use this to act as the nil
    WPAnalyticsStatApplicationOpened,
    WPAnalyticsStatApplicationClosed,
    WPAnalyticsStatThemesAccessedThemeBrowser,
    WPAnalyticsStatThemesChangedTheme,
    WPAnalyticsStatReaderAccessed,
    WPAnalyticsStatReaderOpenedArticle,
    WPAnalyticsStatReaderLikedArticle,
    WPAnalyticsStatReaderRebloggedArticle,
    WPAnalyticsStatReaderInfiniteScroll,
    WPAnalyticsStatReaderFollowedReaderTag,
    WPAnalyticsStatReaderUnfollowedReaderTag,
    WPAnalyticsStatReaderFollowedSite,
    WPAnalyticsStatReaderLoadedTag,
    WPAnalyticsStatReaderLoadedFreshlyPressed,
    WPAnalyticsStatReaderCommentedOnArticle,
    WPAnalyticsStatStatsAccessed,
    WPAnalyticsStatEditorCreatedPost,
    WPAnalyticsStatEditorAddedPhotoViaLocalLibrary,
    WPAnalyticsStatEditorAddedPhotoViaWPMediaLibrary,
    WPAnalyticsStatEditorUpdatedPost,
    WPAnalyticsStatEditorScheduledPost,
    WPAnalyticsStatEditorPublishedPost,
    WPAnalyticsStatEditorClosed,
    WPAnalyticsStatEditorDiscardedChanges,
    WPAnalyticsStatEditorSavedDraft,
    WPAnalyticsStatPublishedPostWithPhoto,
    WPAnalyticsStatPublishedPostWithVideo,
    WPAnalyticsStatPublishedPostWithCategories,
    WPAnalyticsStatPublishedPostWithTags,
    WPAnalyticsStatNotificationsAccessed,
    WPAnalyticsStatNotificationsOpenedNotificationDetails,
    WPAnalyticsStatOpenedPosts,
    WPAnalyticsStatOpenedPages,
    WPAnalyticsStatOpenedComments,
    WPAnalyticsStatOpenedViewSite,
    WPAnalyticsStatOpenedViewAdmin,
    WPAnalyticsStatOpenedMediaLibrary,
    WPAnalyticsStatOpenedSettings,
    WPAnalyticsStatCreatedAccount,
    WPAnalyticsStatSharedItem,
    WPAnalyticsStatSharedItemViaEmail,
    WPAnalyticsStatSharedItemViaSMS,
    WPAnalyticsStatSharedItemViaTwitter,
    WPAnalyticsStatSharedItemViaFacebook,
    WPAnalyticsStatSharedItemViaWeibo,
    WPAnalyticsStatSentItemToInstapaper,
    WPAnalyticsStatSentItemToPocket,
    WPAnalyticsStatSentItemToGooglePlus,
    WPAnalyticsStatSentItemToWordPress,
    WPAnalyticsStatNotificationPerformedAction,
    WPAnalyticsStatNotificationRepliedTo,
    WPAnalyticsStatNotificationApproved,
    WPAnalyticsStatNotificationTrashed,
    WPAnalyticsStatNotificationFlaggedAsSpam,
    WPAnalyticsStatAddedSelfHostedSite,
    WPAnalyticsStatAddedSelfHostedSiteButJetpackNotConnectedToWPCom,
    WPAnalyticsStatSkippedConnectingToJetpack,
    WPAnalyticsStatSignedInToJetpack,
    WPAnalyticsStatSelectedLearnMoreInConnectToJetpackScreen,
    WPAnalyticsStatPerformedJetpackSignInFromStatsScreen,
    WPAnalyticsStatSelectedInstallJetpack,
};

@protocol WPAnalyticsTracker;
@interface WPAnalytics : NSObject

+ (void)registerTracker:(id<WPAnalyticsTracker>)tracker;
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
