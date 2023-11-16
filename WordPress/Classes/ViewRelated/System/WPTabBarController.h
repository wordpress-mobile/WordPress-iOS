#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const WPNewPostURLParamContentKey;
extern NSString * const WPNewPostURLParamTagsKey;
extern NSString * const WPTabBarCurrentlySelectedScreenSites;
extern NSString * const WPTabBarCurrentlySelectedScreenReader;
extern NSString * const WPTabBarCurrentlySelectedScreenNotifications;
extern NSNotificationName const WPTabBarHeightChangedNotification;

@class AbstractPost;
@class Blog;
@class BloggingPromptCoordinator;
@class BlogListViewController;
@class MeViewController;
@class MySitesCoordinator;
@class NotificationsViewController;
@class ReaderCoordinator;
@class ReaderTabViewModel;
@class WPSplitViewController;
@protocol ScenePresenter;

@interface WPTabBarController : UITabBarController <UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, readonly, nullable) NotificationsViewController *notificationsViewController;
@property (nonatomic, strong, readonly, nullable) UINavigationController *readerNavigationController;
@property (nonatomic, strong, readonly, nullable) MeViewController *meViewController;
@property (nonatomic, strong, readonly, nullable) UINavigationController *meNavigationController;
@property (nonatomic, strong, readonly, nonnull) MySitesCoordinator *mySitesCoordinator;
@property (nonatomic, strong, readonly, nullable) ReaderCoordinator *readerCoordinator;
@property (nonatomic, strong) id<ScenePresenter> meScenePresenter;
@property (nonatomic, strong, readonly) ReaderTabViewModel *readerTabViewModel;

- (instancetype)initWithStaticScreens:(BOOL)shouldUseStaticScreens;

- (NSString *)currentlySelectedScreen;

- (UIViewController *)notificationsSplitViewController;
- (void)showMySitesTab;
- (void)showReaderTab;
- (void)resetReaderTab;
- (void)showNotificationsTab;
- (void)showReaderTabForPost:(NSNumber *)postId onBlog:(NSNumber *)blogId;
- (void)showMeTab;
- (void)reloadSplitViewControllers;

- (void)popNotificationsTabToRoot;
- (void)switchNotificationsTabToNotificationSettings;

- (void)showNotificationsTabForNoteWithID:(NSString *)notificationID;
- (void)updateNotificationBadgeVisibility;

@end

NS_ASSUME_NONNULL_END
