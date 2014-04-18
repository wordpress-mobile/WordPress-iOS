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
    WPAnalyticsStatReaderLoadedTag,
    WPAnalyticsStatReaderLoadedFreshlyPressed,
    WPAnalyticsStatReaderCommentedOnArticle,
    WPAnalyticsStatStatsAccessed,
    WPAnalyticsStatEditorCreatedPost,
    WPAnalyticsStatEditorAddedPhotoViaLocalLibrary,
    WPAnalyticsStatEditorAddedPhotoViaWPMediaLibrary,
    WPAnalyticsStatEditorUpdatedPost,
    WPAnalyticsStatEditorPublishedPost,
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
    WPAnalyticsStatNotificationPerformedAction,
    WPAnalyticsStatNotificationRepliedTo,
    WPAnalyticsStatNotificationApproved,
    WPAnalyticsStatNotificationTrashed,
    WPAnalyticsStatNotificationFlaggedAsSpam,
    WPAnalyticsStatAddedSelfHostedSiteWithoutJetpack,
    WPAnalyticsStatAddedSelfHostedSiteButJetpackNotConnectedToWPCom,
    WPAnalyticsStatAddedSelfHostedSiteButSkippedConnectingToJetpack,
    WPAnalyticsStatAddedSelfHostedSiteAndSignedInToJetpack,
    WPAnalyticsStatSelectedLearnMoreInConnectToJetpackScreen,
    WPAnalyticsStatPerformedJetpackSignInFromStatsScreen,
    WPAnalyticsStatSelectedInstallJetpack,
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
