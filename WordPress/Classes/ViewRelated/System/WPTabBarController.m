#import "WPTabBarController.h"

#import "AccountService.h"
@import WordPressDataObjC;
#import "BlogService.h"
#import "Blog.h"

#import "BlogDetailsViewController.h"
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"

@import Gridicons;
@import WordPressShared;
@import WordPressUI;

static NSString * const WPTabBarButtonClassname = @"UITabBarButton";
static NSString * const WPApplicationIconBadgeNumberKeyPath = @"applicationIconBadgeNumber";

NSString * const WPNewPostURLParamTitleKey = @"title";
NSString * const WPNewPostURLParamContentKey = @"content";
NSString * const WPNewPostURLParamTagsKey = @"tags";
NSString * const WPNewPostURLParamImageKey = @"image";

NSString * const WPTabBarCurrentlySelectedScreenSites = @"Blog List";
NSString * const WPTabBarCurrentlySelectedScreenReader = @"Reader";
NSString * const WPTabBarCurrentlySelectedScreenNotifications = @"Notifications";

NSNotificationName const WPTabBarHeightChangedNotification = @"WPTabBarHeightChangedNotification";
static NSString * const WPTabBarFrameKeyPath = @"frame";

static NSInteger const WPTabBarIconOffsetiPad = 7;
static NSInteger const WPTabBarIconOffsetiPhone = 5;

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

@end

@implementation WPTabBarController

#pragma mark - Instance methods

- (instancetype)initWithStaticScreens:(BOOL)shouldUseStaticScreens
{
    self = [super init];
    if (self) {
        _shouldUseStaticScreens = shouldUseStaticScreens;
        [self setDelegate:self];
        [[self tabBar] setAccessibilityIdentifier:@"Main Navigation"];
        [[self tabBar] setAccessibilityLabel:NSLocalizedString(@"Main Navigation", nil)];
        [WPStyleGuide configureTabBar:[self tabBar]];

        [self setViewControllers:[self tabViewControllers]];

        [self setSelectedViewController:self.mySitesCoordinator.rootViewController];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateIconIndicators:)
                                                     name:NSNotification.ZendeskPushNotificationReceivedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateIconIndicators:)
                                                     name:NSNotification.ZendeskPushNotificationClearedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(defaultAccountDidChange:)
                                                     name:WPAccountDefaultWordPressComAccountChangedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(signinDidFinish:)
                                                     name:WPTabBarController.wpSigninDidFinishNotification
                                                   object:nil];

        // Watch for application badge number changes
        [[UIApplication sharedApplication] addObserver:self
                                            forKeyPath:WPApplicationIconBadgeNumberKeyPath
                                               options:NSKeyValueObservingOptionNew
                                               context:nil];

        [self.tabBar addObserver:self
                      forKeyPath:WPTabBarFrameKeyPath
                         options:NSKeyValueObservingOptionNew
                         context:nil];

        [self observeGravatarImageUpdate];
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
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:WPApplicationIconBadgeNumberKeyPath];
}

#pragma mark - Tab Bar Items

- (UINavigationController *)readerNavigationController
{
    if (!_readerNavigationController) {
        if (self.shouldUseStaticScreens) {
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
    if (self.shouldUseStaticScreens) {
        rootViewController = [[MovedToJetpackViewController alloc] initWithSource:MovedToJetpackSourceNotifications];
    } else {
        UIStoryboard *notificationsStoryboard = [UIStoryboard storyboardWithName:@"Notifications" bundle:nil];
        self.notificationsViewController = [notificationsStoryboard instantiateInitialViewController];
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

- (UINavigationController *)meNavigationController
{
    if (!_meNavigationController) {
        _meNavigationController = [[UINavigationController alloc] initWithRootViewController:self.meViewController];
        [self configureMeTabImageWithPlaceholderImage:[UIImage imageNamed:@"tab-bar-me"]];
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

- (UIEdgeInsets)tabBarIconImageInsets
{
    CGFloat offset = 0;
    if ([WPDeviceIdentification isiPad]) {
        offset = WPTabBarIconOffsetiPad;
    } else {
        offset = WPTabBarIconOffsetiPhone;
    }

    return UIEdgeInsetsMake(offset, 0, -offset, 0);
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

- (void)switchNotificationsTabToNotificationSettings
{
    [self showNotificationsTab];
    [self.notificationsNavigationController popToRootViewControllerAnimated:NO];

    [self.notificationsViewController showNotificationSettings];
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

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [generator impactOccurred];

    [self animateSelectedItem:item for:tabBar];
}

#pragma mark - Zendesk Notifications

- (void)updateIconIndicators:(NSNotification *)notification
{
    [self updateNotificationBadgeVisibility];
}

#pragma mark - Default Account Notifications

- (void)defaultAccountDidChange:(NSNotification *)notification
{
    if (notification.object == nil) {
        [self.readerNavigationController popToRootViewControllerAnimated:NO];
        [self.notificationsNavigationController popToRootViewControllerAnimated:NO];
    }

    self.readerNavigationController = nil;
}

- (void)signinDidFinish:(NSNotification *)notification
{
    [self reloadTabs];
}

#pragma mark - Handling Badges

- (void)updateNotificationBadgeVisibility
{
    UITabBarItem *notificationsTabBarItem = self.notificationsNavigationController.tabBarItem;
    
    if (self.shouldUseStaticScreens) {
        notificationsTabBarItem.image = self.notificationsTabBarImage;
        notificationsTabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
        return;
    }

    // Discount Zendesk unread notifications when determining if we need to show the notificationsTabBarImageUnread.
    NSInteger count = [[UIApplication sharedApplication] applicationIconBadgeNumber] - [ZendeskUtils unreadNotificationsCount];
    if (count > 0 || ![self welcomeNotificationSeen]) {
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

    if (object == [UIApplication sharedApplication] && [keyPath isEqualToString:WPApplicationIconBadgeNumberKeyPath]) {
        [self updateNotificationBadgeVisibility];
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

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    if ([presented isKindOfClass:[FancyAlertViewController class]]) {
        return [[FancyAlertPresentationController alloc] initWithPresentedViewController:presented
                                                                presentingViewController:presenting];
    }

    return nil;
}

@end
