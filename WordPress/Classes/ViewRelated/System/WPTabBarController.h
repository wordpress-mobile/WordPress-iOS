#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const WPTabBarCurrentlySelectedScreenSites;
extern NSString * const WPTabBarCurrentlySelectedScreenReader;
extern NSString * const WPTabBarCurrentlySelectedScreenNotifications;
extern NSNotificationName const WPTabBarHeightChangedNotification;

@class MeViewController;
@class MySitesCoordinator;
@class NotificationsViewController;
@class ReaderPresenter;

@interface WPTabBarController : UITabBarController

@property (nonatomic, strong, readonly, nullable) NotificationsViewController *notificationsViewController;
@property (nonatomic, strong, readonly, nonnull) UINavigationController *notificationsNavigationController;
@property (nonatomic, strong, readonly, nonnull) UINavigationController *readerNavigationController;
@property (nonatomic, strong, readonly, nonnull) MeViewController *meViewController;
@property (nonatomic, strong, readonly, nonnull) UINavigationController *meNavigationController;
@property (nonatomic, strong, readonly, nonnull) MySitesCoordinator *mySitesCoordinator;
@property (nonatomic, strong, readonly, nullable) ReaderPresenter *readerPresenter;
/// Whether the Reader tab shows the Moved-to-Jetpack poster instead of the live Reader.
/// Changing it replaces the Reader tab's screens; the other tabs keep their state.
@property (nonatomic, assign) BOOL shouldUseStaticReader;
/// Whether the Notifications tab shows the Moved-to-Jetpack poster instead of the live list.
/// Changing it rebuilds the Notifications tab; the other tabs keep their state.
@property (nonatomic, assign) BOOL shouldUseStaticNotifications;

- (instancetype)initWithStaticScreens:(BOOL)shouldUseStaticScreens;
- (instancetype)initWithStaticReader:(BOOL)shouldUseStaticReader
                 staticNotifications:(BOOL)shouldUseStaticNotifications;

- (NSString *)currentlySelectedScreen;

- (void)showMySitesTab;
- (void)showReaderTab;
- (void)showMeTab;

- (void)updateNotificationBadgeVisibility;

@end

NS_ASSUME_NONNULL_END
