#import <UIKit/UIKit.h>

extern NSString * const WPNewPostURLParamContentKey;
extern NSString * const WPNewPostURLParamTagsKey;

typedef NS_ENUM(NSUInteger, WPTabType) {
    WPTabMySites,
    WPTabReader,
    WPTabNewPost,
    WPTabMe,
    WPTabNotifications
};

@class AbstractPost;
@class Blog;
@class BlogListViewController;
@class MeViewController;
@class NotificationsViewController;
@class ReaderCoordinator;
@class ReaderMenuViewController;
@class WPSplitViewController;

@interface WPTabBarController : UITabBarController

@property (nonatomic, strong, readonly) WPSplitViewController *blogListSplitViewController;
@property (nonatomic, strong, readonly) BlogListViewController *blogListViewController;
@property (nonatomic, strong, readonly) ReaderMenuViewController *readerMenuViewController;
@property (nonatomic, strong, readonly) NotificationsViewController *notificationsViewController;
@property (nonatomic, strong, readonly) MeViewController *meViewController;

@property (nonatomic, strong, readonly) ReaderCoordinator *readerCoordinator;

+ (instancetype)sharedInstance;

- (NSString *)currentlySelectedScreen;
- (BOOL)isNavigatingMySitesTab;

- (void)showMySitesTab;
- (void)showReaderTab;
- (void)showPostTab;
- (void)showPostTabForBlog:(Blog *)blog;
- (void)showMeTab;
- (void)showNotificationsTab;
- (void)showPostTabAnimated:(BOOL)animated toMedia:(BOOL)openToMedia;
- (void)showReaderTabForPost:(NSNumber *)postId onBlog:(NSNumber *)blogId;

- (void)switchMySitesTabToAddNewSite;
- (void)switchMySitesTabToStatsViewForBlog:(Blog *)blog;
- (void)switchMySitesTabToMediaForBlog:(Blog *)blog;
- (void)switchMySitesTabToCustomizeViewForBlog:(Blog *)blog;
- (void)switchMySitesTabToThemesViewForBlog:(Blog *)blog;
- (void)switchTabToPostsListForPost:(AbstractPost *)post;
- (void)switchTabToPagesListForPost:(AbstractPost *)post;
- (void)switchMySitesTabToBlogDetailsForBlog:(Blog *)blog;

- (void)switchMeTabToAccountSettings;
- (void)switchMeTabToAppSettings;
- (void)switchMeTabToNotificationSettings;
- (void)switchMeTabToSupport;

- (void)popMeTabToRoot;
- (void)popNotificationsTabToRoot;

- (void)switchReaderTabToSavedPosts;

- (void)showNotificationsTabForNoteWithID:(NSString *)notificationID;
- (void)updateNotificationBadgeVisibility;

@end
