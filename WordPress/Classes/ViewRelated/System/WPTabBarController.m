#import "WPTabBarController.h"

#import "WordPress-Swift.h"

@import WordPressData;
@import WordPressShared;
@import WordPressSharedObjCUI;
@import WordPressUI;

NSString * const WPTabBarCurrentlySelectedScreenSites = @"Blog List";
NSString * const WPTabBarCurrentlySelectedScreenReader = @"Reader";
NSString * const WPTabBarCurrentlySelectedScreenNotifications = @"Notifications";

NSNotificationName const WPTabBarHeightChangedNotification = @"WPTabBarHeightChangedNotification";
static NSString * const WPTabBarFrameKeyPath = @"frame";

@interface WPTabBarController () <UITabBarControllerDelegate>

@property (nonatomic, strong) NotificationsViewController *notificationsViewController;

@property (nonatomic, strong) MeViewController *meViewController;

@property (nonatomic, strong, nullable) MySitesCoordinator *mySitesCoordinator;
@property (nonatomic, strong, nullable) ReaderPresenter *readerPresenter;

@property (nonatomic, strong) UIImage *notificationsTabBarImage;
@property (nonatomic, strong) UIImage *notificationsTabBarImageUnread;
@property (nonatomic, strong) UIImage *meTabBarImage;
@property (nonatomic, strong) UIImage *meTabBarImageUnreadUnselected;
@property (nonatomic, strong) UIImage *meTabBarImageUnreadSelected;

@property (nonatomic, assign) CGFloat tabBarHeight;

@end

@implementation WPTabBarController

#pragma mark - Instance methods

- (instancetype)initWithStaticScreens:(BOOL)shouldUseStaticScreens
{
    return [self initWithStaticReader:shouldUseStaticScreens staticNotifications:shouldUseStaticScreens];
}

- (instancetype)initWithStaticReader:(BOOL)shouldUseStaticReader
                 staticNotifications:(BOOL)shouldUseStaticNotifications
{
    self = [super init];
    if (self) {
        _shouldUseStaticReader = shouldUseStaticReader;
        _shouldUseStaticNotifications = shouldUseStaticNotifications;
        [self setDelegate:self];
        [[self tabBar] setAccessibilityIdentifier:@"Main Navigation"];
        [[self tabBar] setAccessibilityLabel:NSLocalizedString(@"Main Navigation", nil)];
        [WPStyleGuide configureTabBar:[self tabBar]];

        // The tabs are built once. Account and app UI changes replace the first screen of a
        // tab, and keep its navigation controller and tab bar item.
        _readerNavigationController = [self makeReaderNavigationController];
        _notificationsNavigationController = [self makeNotificationsNavigationController];
        _meNavigationController = [self makeMeNavigationController];
        [self observeAccountAvatar];
        [self setViewControllers:@[
            self.mySitesCoordinator.rootViewController,
            _readerNavigationController,
            _notificationsNavigationController,
            _meNavigationController
        ]];

        [self setSelectedViewController:self.mySitesCoordinator.rootViewController];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateIconIndicators:)
                                                     name:ObjCBridge.notificationActivityDidChangeNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(defaultAccountDidChange:)
                                                     name:NSNotification.wpAccountDefaultWordPressComAccountChangedNotificationName
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(signinDidFinish:)
                                                     name:WPTabBarController.wpSigninDidFinishNotification
                                                   object:nil];

        [self.tabBar addObserver:self
                      forKeyPath:WPTabBarFrameKeyPath
                         options:NSKeyValueObservingOptionNew
                         context:nil];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithStaticScreens:NO];
}

- (void)dealloc
{
    [self.tabBar removeObserver:self forKeyPath:WPTabBarFrameKeyPath];
}

#pragma mark - Tab Bar Items

- (UINavigationController *)makeReaderNavigationController
{
    UINavigationController *navigationController = [UINavigationController new];
    navigationController.view.backgroundColor = [UIColor systemBackgroundColor];

    navigationController.tabBarItem.image = [UIImage imageNamed:@"tab-bar-reader"];
    navigationController.tabBarItem.accessibilityIdentifier = @"tabbar_reader";
    navigationController.tabBarItem.title = [WPTabBarController readerLocalizedTitle];

    UITabBarAppearance *scrollEdgeAppearance = [UITabBarAppearance new];
    [scrollEdgeAppearance configureWithOpaqueBackground];
    navigationController.tabBarItem.scrollEdgeAppearance = scrollEdgeAppearance;

    [self showFirstReaderScreenInNavigationController:navigationController];
    return navigationController;
}

/// Replaces the Reader tab's screens with a first screen for the current account.
- (void)showFirstReaderScreenInNavigationController:(UINavigationController *)navigationController
{
    if (self.shouldUseStaticReader) {
        self.readerPresenter = nil;
        UIViewController *rootVC = [[MovedToJetpackViewController alloc] initWithSource:MovedToJetpackSourceReader];
        [navigationController setViewControllers:@[rootVC] animated:NO];
    } else {
        self.readerPresenter = [[ReaderPresenter alloc] init];
        [self.readerPresenter prepareForTabBarPresentationInNavigationController:navigationController];
    }
}

- (UINavigationController *)makeNotificationsNavigationController
{
    UINavigationController *navigationController = [UINavigationController new];
    self.notificationsTabBarImage = [UIImage imageNamed:@"tab-bar-notifications"];
    self.notificationsTabBarImageUnread = [[UIImage imageNamed:@"tab-bar-notifications-unread"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    navigationController.tabBarItem.image = self.notificationsTabBarImage;
    navigationController.tabBarItem.accessibilityIdentifier = @"tabbar_notifications";
    navigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    navigationController.tabBarItem.title = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");

    [self showFirstNotificationsScreenInNavigationController:navigationController];
    return navigationController;
}

/// Replaces the Notifications tab's screens with a new list, or the Moved-to-Jetpack poster.
- (void)showFirstNotificationsScreenInNavigationController:(UINavigationController *)navigationController
{
    UIViewController *rootViewController;
    if (self.shouldUseStaticNotifications) {
        // The poster can replace a live list; drop the old list with it.
        self.notificationsViewController = nil;
        rootViewController = [[MovedToJetpackViewController alloc] initWithSource:MovedToJetpackSourceNotifications];
    } else {
        self.notificationsViewController = [NotificationsViewController makeForAppNavigation];
        rootViewController = self.notificationsViewController;
    }
    [navigationController setViewControllers:@[rootViewController] animated:NO];
}

- (void)setShouldUseStaticNotifications:(BOOL)shouldUseStaticNotifications
{
    if (_shouldUseStaticNotifications == shouldUseStaticNotifications) {
        return;
    }
    _shouldUseStaticNotifications = shouldUseStaticNotifications;

    [self showFirstNotificationsScreenInNavigationController:self.notificationsNavigationController];
    [self updateNotificationBadgeVisibility];
}

- (UINavigationController *)makeMeNavigationController
{
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.meViewController];
    navigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Me", @"The accessibility value of the me tab.");
    navigationController.tabBarItem.accessibilityIdentifier = @"tabbar_me";
    navigationController.tabBarItem.title = NSLocalizedString(@"Me", @"The accessibility value of the me tab.");
    return navigationController;
}

- (MeViewController *)meViewController {
    if (!_meViewController) {
        _meViewController = [[MeViewController alloc] init];
    }

    return _meViewController;
}

- (void)reloadTabs
{
    // `defaultAccountDidChange:` already resets the Reader tab, which depends only
    // on the WordPress.com account.
    [self showFirstNotificationsScreenInNavigationController:self.notificationsNavigationController];
    [self.meNavigationController popToRootViewControllerAnimated:NO];

    // Reset the selectedIndex to the default MySites tab.
    self.selectedIndex = WPTabMySites;
}

#pragma mark - Navigation Coordinators

- (MySitesCoordinator *)mySitesCoordinator
{
    if (!_mySitesCoordinator) {
        __weak __typeof(self) weakSelf = self;

        _mySitesCoordinator = [[MySitesCoordinator alloc] initOnBecomeActiveTab:^{
            [weakSelf showMySitesTab];
        }];
    }

    return _mySitesCoordinator;
}

#pragma mark - Tab Selection

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];
    [self updateTabBarMinimizeBehavior];
}

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController
{
    [super setSelectedViewController:selectedViewController];
    [self updateTabBarMinimizeBehavior];
}

- (void)showMySitesTab
{
    [self setSelectedIndex:WPTabMySites];
}

- (void)showReaderTab
{
    [self setSelectedIndex:WPTabReader];
}

- (void)showNotificationsTab
{
    [self setSelectedIndex:WPTabNotifications];
}

- (void)showMeTab
{
    [self setSelectedIndex:WPTabMe];
}

- (void)popNotificationsTabToRoot
{
    [self.notificationsNavigationController popToRootViewControllerAnimated:NO];
}

- (NSString *)currentlySelectedScreen
{
    // Check which tab is currently selected
    NSString *currentlySelectedScreen = @"";
    switch (self.selectedIndex) {
        case WPTabMySites:
            currentlySelectedScreen = WPTabBarCurrentlySelectedScreenSites;
            break;
        case WPTabReader:
            currentlySelectedScreen = WPTabBarCurrentlySelectedScreenReader;
            break;
        case WPTabNotifications:
            currentlySelectedScreen = WPTabBarCurrentlySelectedScreenNotifications;
            break;
        default:
            break;
    }
    return currentlySelectedScreen;
}

#pragma mark - UITabBarControllerDelegate methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    NSUInteger selectedIndex = [tabBarController.viewControllers indexOfObject:viewController];

    // If we're selecting a new tab...
    if (selectedIndex != tabBarController.selectedIndex) {
        [self trackTabAccessForTabIndex:selectedIndex];
    } else {
        // If the current view controller is selected already and it's at its root then scroll to the top
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navController = (UINavigationController *)viewController;
            [navController scrollContentToTopAnimated:YES];
        }
    }

    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    [self updateTabBarMinimizeBehavior];
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
    [generator impactOccurred];

    [self animateSelectedItem:item for:tabBar];
}

#pragma mark - Notification Activity

- (void)updateIconIndicators:(NSNotification *)notification
{
    [self updateNotificationBadgeVisibility];
}

#pragma mark - Default Account Notifications

- (void)defaultAccountDidChange:(NSNotification *)notification
{
    // The Reader tab's first screen and presenter depend on the account, so replace
    // them for every change, including the same account signing in again.
    [self showFirstReaderScreenInNavigationController:self.readerNavigationController];

    if (notification.object == nil) {
        [self.notificationsNavigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)signinDidFinish:(NSNotification *)notification
{
    [self reloadTabs];
}

#pragma mark - Handling Badges

- (void)updateNotificationBadgeVisibility
{
    UITabBarItem *notificationsTabBarItem = self.notificationsNavigationController.tabBarItem;
    
    if (self.shouldUseStaticNotifications) {
        notificationsTabBarItem.image = self.notificationsTabBarImage;
        notificationsTabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
        return;
    }

    // The bell is driven by the account-scoped in-app activity state, not the
    // home-screen icon badge. Support keeps its own indicators elsewhere.
    if (ObjCBridge.hasNewNotificationActivity || ![self welcomeNotificationSeen]) {
        notificationsTabBarItem.image = self.notificationsTabBarImageUnread;
        notificationsTabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications Unread", @"Notifications tab bar item accessibility label, unread notifications state");
    } else {
        notificationsTabBarItem.image = self.notificationsTabBarImage;
        notificationsTabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    }

    if (UIApplication.sharedApplication.isCreatingScreenshots) {
        notificationsTabBarItem.image = self.notificationsTabBarImage;
        notificationsTabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    }
    
}

- (BOOL)welcomeNotificationSeen
{
    NSUserDefaults *standardUserDefaults = [UserPersistentStoreFactory userDefaultsInstance];
    NSString *welcomeNotificationSeenKey = @"welcomeNotificationSeen";
    return [standardUserDefaults boolForKey: welcomeNotificationSeenKey];
}

#pragma mark - NSObject(NSKeyValueObserving) Helpers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.tabBar && [keyPath isEqualToString:WPTabBarFrameKeyPath]) {
        [self notifyOfTabBarHeightChangedIfNeeded];
    }
}

- (void)notifyOfTabBarHeightChangedIfNeeded
{
    CGFloat newTabBarHeight = self.tabBar.frame.size.height;
    if (newTabBarHeight != self.tabBarHeight) {
        self.tabBarHeight = newTabBarHeight;
        [[NSNotificationCenter defaultCenter] postNotificationName:WPTabBarHeightChangedNotification
                                                            object:nil];
    }
}

#pragma mark - UIResponder & Keyboard Helpers

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (NSArray<UIKeyCommand *>*)keyCommands {
    if (self.presentedViewController) {
        return nil;
    }

    UIKeyCommand *showMySitesTabCommand = [UIKeyCommand keyCommandWithInput:@"1" modifierFlags:UIKeyModifierCommand action:@selector(showMySitesTab)];
    showMySitesTabCommand.discoverabilityTitle = NSLocalizedString(@"My Site", @"The accessibility value of the my site tab.");
    
    UIKeyCommand *showReaderTabCommand = [UIKeyCommand keyCommandWithInput:@"2" modifierFlags:UIKeyModifierCommand action:@selector(showReaderTab)];
    showMySitesTabCommand.discoverabilityTitle = [WPTabBarController readerLocalizedTitle];
    
    UIKeyCommand *showNotificationsTabCommand = [UIKeyCommand keyCommandWithInput:@"4" modifierFlags:UIKeyModifierCommand action:@selector(showNotificationsTab)];
    showMySitesTabCommand.discoverabilityTitle = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    
    
    return @[showMySitesTabCommand, showReaderTabCommand, showNotificationsTabCommand];
}

#pragma mark - Handling Layout

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.accessibilityIdentifier = @"root_vc";
    [self startObserversForTabAccessTracking];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateNotificationBadgeVisibility];

    [self trackTabAccessOnViewDidAppear];
}

@end
