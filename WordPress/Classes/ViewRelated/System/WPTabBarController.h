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
@class MeViewController;
@class MySitesCoordinator;
@class NotificationsViewController;
@class ReaderPresenter;
@protocol ScenePresenter;

@interface WPTabBarController : UITabBarController <UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, readonly, nullable) NotificationsViewController *notificationsViewController;
@property (nonatomic, strong, readonly, nullable) UINavigationController *readerNavigationController;
@property (nonatomic, strong, readonly, nonnull) MeViewController *meViewController;
@property (nonatomic, strong, readonly, nonnull) UINavigationController *meNavigationController;
@property (nonatomic, strong, readonly, nonnull) MySitesCoordinator *mySitesCoordinator;
@property (nonatomic, strong, readonly, nullable) ReaderPresenter *readerPresenter;
@property (nonatomic, assign) BOOL shouldUseStaticScreens;

- (instancetype)initWithStaticScreens:(BOOL)shouldUseStaticScreens;

- (NSString *)currentlySelectedScreen;

- (void)showMySitesTab;
- (void)showReaderTab;
- (void)showMeTab;

- (void)updateNotificationBadgeVisibility;

@end

NS_ASSUME_NONNULL_END
