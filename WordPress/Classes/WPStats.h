#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WPStat) {
    WPStatApplicationOpened,
    WPStatApplicationClosed,
    WPStatThemesAccessThemeBrowser,
    WPStatThemesChangeATheme,
    WPStatReaderAccessedReader,
    WPStatReaderOpenArticle,
    WPStatReaderLikeArticle,
    WPStatReaderReblogArticle,
    WPStatReaderLoadMoreArticles,
    WPStatReaderFollowReaderTag,
    WPStatReaderUnfollowReaderTag,
    WPStatReaderFilterByReaderTag,
    WPStatReaderLoadFreshlyPressed,
    WPStatReaderCommentOnArticle,
    WPStatStatsAccessStats,
    WPStatEditorCreatePost,
    WPStatEditorAddPhotoViaLocalLibrary,
    WPStatEditorAddPhotoViaWPMediaLibrary,
    WPStatEditorUpdatePost,
    WPStatEditorPublishPost,
    WPStatNotificationsAccessNotifications,
    WPStatNotificationsOpenNotificationDetails,
};

@interface WPStats : NSObject

+ (void)track:(WPStat)stat;

@end

@protocol WPStatsClient <NSObject>

- (void)track:(WPStat)stat;

@end
