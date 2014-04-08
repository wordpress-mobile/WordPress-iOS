#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WPStat) {
    WPStatApplicationOpened,
    WPStatApplicationClosed,
    WPStatThemesAccessThemeBrowser,
    WPStatThemesChangedTheme,
    WPStatReaderAccessedReader,
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
    WPStatNotificationsAccessedNotifications,
    WPStatNotificationsOpenedNotificationDetails,
    WPStatOpenedPosts,
    WPStatOpenedPages,
    WPStatOpenedComments,
    WPStatOpenedViewSite,
    WPStatOpenedViewAdmin,
    WPStatOpenedMediaLibrary,
    WPStatOpenedSettings,
    WPStatCreatedAccount,
};

@interface WPStats : NSObject

+ (void)track:(WPStat)stat;
+ (void)track:(WPStat)stat withProperties:(NSDictionary *)properties;
+ (void)endSession;

@end

@protocol WPStatsClient <NSObject>

- (void)track:(WPStat)stat;
- (void)track:(WPStat)stat withProperties:(NSDictionary *)properties;
- (void)endSession;

@end
