#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WPStat) {
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
    WPStatReaderFilteredByReaderTag,
    WPStatReaderLoadedFreshlyPressed,
    WPStatReaderCommentedOnArticle,
    WPStatStatsAccessedStats,
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

@protocol WPStatsClient;
@interface WPStats : NSObject

+ (void)registerClient:(id<WPStatsClient>)client;
+ (void)beginSession;
+ (void)track:(WPStat)stat;
+ (void)track:(WPStat)stat withProperties:(NSDictionary *)properties;
+ (void)endSession;

@end

@protocol WPStatsClient <NSObject>

- (void)track:(WPStat)stat;
- (void)track:(WPStat)stat withProperties:(NSDictionary *)properties;

@optional
- (void)beginSession;
- (void)endSession;

@end
