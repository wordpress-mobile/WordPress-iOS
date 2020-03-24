#import <UIKit/UIKit.h>

extern NSString * const WPNewPostURLParamContentKey;
extern NSString * const WPNewPostURLParamTagsKey;
//TODO: Remove WPTabMe and WPTabNewPost when the new Me page and FAB are released
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
@class MySitesCoordinator;
@class NotificationsViewController;
@class ReaderCoordinator;
@class ReaderMenuViewController;
@class CreateButtonCoordinator;
@class WPSplitViewController;
@class QuickStartTourGuide;
@protocol ScenePresenter;

@interface WPTabBarController : UITabBarController <UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, readonly) WPSplitViewController *blogListSplitViewController;
@property (nonatomic, strong, readonly) BlogListViewController *blogListViewController;
@property (nonatomic, strong, readonly) UINavigationController *blogListNavigationController;
@property (nonatomic, strong, readonly) ReaderMenuViewController *readerMenuViewController;
@property (nonatomic, strong, readonly) NotificationsViewController *notificationsViewController;
// will be removed when the new IA implementation completes
@property (nonatomic, strong, readonly) MeViewController *meViewController;
// will be removed when the new IA implementation completes
@property (nonatomic, strong, readonly) UINavigationController *meNavigationController;
@property (nonatomic, strong, readonly) QuickStartTourGuide *tourGuide;
@property (nonatomic, strong, readonly) MySitesCoordinator *mySitesCoordinator;
@property (nonatomic, strong, readonly) ReaderCoordinator *readerCoordinator;
@property (nonatomic, strong) id<ScenePresenter> meScenePresenter;
@property (nonatomic, strong, readonly) CreateButtonCoordinator *createButtonCoordinator;

+ (instancetype)sharedInstance;

- (NSString *)currentlySelectedScreen;
- (BOOL)isNavigatingMySitesTab;

- (void)showMySitesTab;
- (void)showReaderTab;
- (void)resetReaderTab;
- (void)showPostTab;
- (void)showPostTabWithCompletion:(void (^)(void))afterDismiss;
- (void)showPostTabForBlog:(Blog *)blog;
// will be removed when the new IA implementation completes
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

- (void)popNotificationsTabToRoot;
- (void)switchNotificationsTabToNotificationSettings;

- (void)switchReaderTabToSavedPosts;

- (void)showNotificationsTabForNoteWithID:(NSString *)notificationID;
- (void)updateNotificationBadgeVisibility;
// will be removed when the new IA implementation completes
- (void)showTabForIndex:(NSInteger)tabIndex;

- (Blog *)currentOrLastBlog;

@end
