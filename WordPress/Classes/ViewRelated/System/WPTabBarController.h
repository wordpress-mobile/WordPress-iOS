#import <UIKit/UIKit.h>

extern NSString * const WPNewPostURLParamContentKey;
extern NSString * const WPNewPostURLParamTagsKey;
extern NSString * const WPTabBarCurrentlySelectedScreenSites;
extern NSString * const WPTabBarCurrentlySelectedScreenReader;
extern NSString * const WPTabBarCurrentlySelectedScreenNotifications;

typedef NS_ENUM(NSUInteger, WPTabType) {
    WPTabMySites,
    WPTabReader,
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
@class ReaderTabViewModel;
@class WPSplitViewController;
@protocol ScenePresenter;

@interface WPTabBarController : UITabBarController <UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, readonly) WPSplitViewController *blogListSplitViewController;
@property (nonatomic, strong, readonly) BlogListViewController *blogListViewController;
@property (nonatomic, strong, readonly) UINavigationController *blogListNavigationController;
@property (nonatomic, strong, readonly) ReaderMenuViewController *readerMenuViewController;
@property (nonatomic, strong, readonly) NotificationsViewController *notificationsViewController;
@property (nonatomic, strong, readonly) UINavigationController *readerNavigationController;
@property (nonatomic, strong, readonly) MySitesCoordinator *mySitesCoordinator;
@property (nonatomic, strong, readonly) ReaderCoordinator *readerCoordinator;
@property (nonatomic, strong) id<ScenePresenter> meScenePresenter;
@property (nonatomic, strong) id<ScenePresenter> whatIsNewScenePresenter;
@property (nonatomic, strong, readonly) ReaderTabViewModel *readerTabViewModel;

+ (instancetype)sharedInstance;

- (NSString *)currentlySelectedScreen;
- (BOOL)isNavigatingMySitesTab;

- (void)showMySitesTab;
- (void)showReaderTab;
- (void)resetReaderTab;
- (void)showPostTab;
- (void)showPostTabWithCompletion:(void (^)(void))afterDismiss;
- (void)showPostTabForBlog:(Blog *)blog;
- (void)showNotificationsTab;
- (void)showPostTabAnimated:(BOOL)animated toMedia:(BOOL)openToMedia;
- (void)showReaderTabForPost:(NSNumber *)postId onBlog:(NSNumber *)blogId;
- (void)switchMySitesTabToAddNewSite;
- (void)switchMySitesTabToStatsViewForBlog:(Blog *)blog;
- (void)switchMySitesTabToMediaForBlog:(Blog *)blog;

- (void)popNotificationsTabToRoot;
- (void)switchNotificationsTabToNotificationSettings;

- (void)showNotificationsTabForNoteWithID:(NSString *)notificationID;
- (void)updateNotificationBadgeVisibility;

- (Blog *)currentOrLastBlog;

@end
