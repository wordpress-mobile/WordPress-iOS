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

@property (nonatomic, strong) UINavigationController *readerNavigationController;
@property (nonatomic, strong) UINavigationController *notificationsNavigationController;

@property (nonatomic, strong) MeViewController *meViewController;
@property (nonatomic, strong) UINavigationController *meNavigationController;

@property (nonatomic, strong, nullable) MySitesCoordinator *mySitesCoordinator;
@property (nonatomic, strong, nullable) ReaderPresenter *readerPresenter;

@property (nonatomic, strong) UIImage *notificationsTabBarImage;
@property (nonatomic, strong) UIImage *notificationsTabBarImageUnread;
@property (nonatomic, strong) UIImage *meTabBarImage;
@property (nonatomic, strong) UIImage *meTabBarImageUnreadUnselected;
@property (nonatomic, strong) UIImage *meTabBarImageUnreadSelected;

@property (nonatomic, assign) CGFloat tabBarHeight;
@property (nonatomic, assign) BOOL hasCompletedFirstAppearance;
@property (nonatomic, strong) NSMutableArray<void (^)(void)> *pendingTabBarItemUpdates;

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
        _pendingTabBarItemUpdates = [NSMutableArray new];
        [self setDelegate:self];
        [[self tabBar] setAccessibilityIdentifier:@"Main Navigation"];
        [[self tabBar] setAccessibilityLabel:NSLocalizedString(@"Main Navigation", nil)];
        [WPStyleGuide configureTabBar:[self tabBar]];

        [self setViewControllers:[self tabViewControllers]];

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

- (UINavigationController *)readerNavigationController
{
    if (!_readerNavigationController) {
        if (self.shouldUseStaticReader) {
            UIViewController *rootVC = [[MovedToJetpackViewController alloc] initWithSource:MovedToJetpackSourceReader];
            _readerNavigationController = [[UINavigationController alloc] initWithRootViewController:rootVC];
        } else {
            _readerPresenter = [[ReaderPresenter alloc] init];
            _readerNavigationController = [_readerPresenter prepareForTabBarPresentation];
        }
        _readerNavigationController.view.backgroundColor = [UIColor systemBackgroundColor];

        _readerNavigationController.tabBarItem.image = [UIImage imageNamed:@"tab-bar-reader"];
        _readerNavigationController.tabBarItem.accessibilityIdentifier = @"tabbar_reader";
        _readerNavigationController.tabBarItem.title = [WPTabBarController readerLocalizedTitle];

        UITabBarAppearance *scrollEdgeAppearance = [UITabBarAppearance new];
        [scrollEdgeAppearance configureWithOpaqueBackground];
        _readerNavigationController.tabBarItem.scrollEdgeAppearance = scrollEdgeAppearance;
    }

    return _readerNavigationController;
}

- (UINavigationController *)notificationsNavigationController
{
    if (_notificationsNavigationController) {
        return _notificationsNavigationController;
    }
    UIViewController *rootViewController;
    if (self.shouldUseStaticNotifications) {
        // A rebuild can replace a live list with the poster; drop the old list with it.
        self.notificationsViewController = nil;
        rootViewController = [[MovedToJetpackViewController alloc] initWithSource:MovedToJetpackSourceNotifications];
    } else {
        self.notificationsViewController = [NotificationsViewController makeForAppNavigation];
        rootViewController = self.notificationsViewController;
    }
    _notificationsNavigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    self.notificationsTabBarImage = [UIImage imageNamed:@"tab-bar-notifications"];
    self.notificationsTabBarImageUnread = [[UIImage imageNamed:@"tab-bar-notifications-unread"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    _notificationsNavigationController.tabBarItem.image = self.notificationsTabBarImage;
    _notificationsNavigationController.tabBarItem.accessibilityIdentifier = @"tabbar_notifications";
    _notificationsNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    _notificationsNavigationController.tabBarItem.title = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");

    return _notificationsNavigationController;
}

- (void)setShouldUseStaticNotifications:(BOOL)shouldUseStaticNotifications
{
    if (_shouldUseStaticNotifications == shouldUseStaticNotifications) {
        return;
    }
    _shouldUseStaticNotifications = shouldUseStaticNotifications;

    _notificationsNavigationController = nil;
    NSUInteger selectedIndex = self.selectedIndex;
    [self setViewControllers:[self tabViewControllers]];
    self.selectedIndex = selectedIndex;
    [self updateNotificationBadgeVisibility];
}

- (UINavigationController *)meNavigationController
{
    if (!_meNavigationController) {
        _meNavigationController = [[UINavigationController alloc] initWithRootViewController:self.meViewController];
        [self observeAccountAvatar];
        _meNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Me", @"The accessibility value of the me tab.");
        _meNavigationController.tabBarItem.accessibilityIdentifier = @"tabbar_me";
        _meNavigationController.tabBarItem.title = NSLocalizedString(@"Me", @"The accessibility value of the me tab.");
    }

    return _meNavigationController;
}

- (MeViewController *)meViewController {
    if (!_meViewController) {
        _meViewController = [[MeViewController alloc] init];
    }

    return _meViewController;
}

- (void)reloadTabs
{
    _readerPresenter = nil;
    _readerNavigationController = nil;
    _notificationsNavigationController = nil;
    _meNavigationController = nil;

    [self setViewControllers:[self tabViewControllers]];
    
    // Reset the selectedIndex to the default MySites tab.
    self.selectedIndex = WPTabMySites;

    // The rebuilt Notifications tab starts with the plain image, and the bell
    // state may have changed before the rebuild.
    [self updateNotificationBadgeVisibility];
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

#pragma mark - Navigation Helpers

- (NSArray<UIViewController *> *)tabViewControllers
{
    return @[
        self.mySitesCoordinator.rootViewController,
        self.readerNavigationController,
        self.notificationsNavigationController,
        self.meNavigationController
    ];
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
    // Discard the Reader tab so `readerNavigationController` rebuilds it for the
    // new account state. Login rebuilds every tab in `signinDidFinish:`.
    _readerPresenter = nil;
    _readerNavigationController = nil;

    if (notification.object == nil) {
        [self.notificationsNavigationController popToRootViewControllerAnimated:NO];
        // Reinstall the tabs. The app UI stays up after logging out when a
        // self-hosted site remains, so the rebuilt Reader tab has to replace the
        // stale one here. The other tabs are the same instances, which keeps the
        // selected tab.
        [self setViewControllers:[self tabViewControllers]];
    }
}

- (void)signinDidFinish:(NSNotification *)notification
{
    [self reloadTabs];
}

#pragma mark - Handling Badges

- (void)updateNotificationBadgeVisibility
{
    __weak __typeof(self) weakSelf = self;
    [self performTabBarItemUpdate:^{
        [weakSelf applyNotificationBadgeVisibility];
    }];
}

- (void)applyNotificationBadgeVisibility
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

#pragma mark - Tab Bar Item Updates

- (void)performTabBarItemUpdate:(void (^)(void))update
{
    // iOS 26 measures each tab button's title once, in the tab bar's first layout
    // pass, and never again. An item image that changes after the tabs are set and
    // before that pass makes the measurement run against icon-only buttons, so
    // every title stays truncated and bottom-anchored until the user taps a tab
    // (FB24250687). This holds whether or not the view is in a window yet, which
    // includes `viewWillAppear:`. So any change once the tab bar has items waits
    // for `viewDidAppear:`. Changes while the tabs are built run immediately,
    // because the tab bar has no items yet, and set the initial images.
    BOOL isAwaitingFirstLayout = self.tabBar.items.count > 0 && !self.hasCompletedFirstAppearance;
    if (isAwaitingFirstLayout) {
        [self.pendingTabBarItemUpdates addObject:[update copy]];
        return;
    }
    update();
}

- (void)flushPendingTabBarItemUpdates
{
    NSArray<void (^)(void)> *updates = [self.pendingTabBarItemUpdates copy];
    [self.pendingTabBarItemUpdates removeAllObjects];
    for (void (^update)(void) in updates) {
        update();
    }
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
    self.hasCompletedFirstAppearance = YES;
    [self flushPendingTabBarItemUpdates];
    [self updateNotificationBadgeVisibility];

    [self trackTabAccessOnViewDidAppear];
}

@end
