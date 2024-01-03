#import "WPTabBarController.h"
#import <WordPressUI/UIImage+Util.h>

#import "AccountService.h"
#import "CoreDataStack.h"
#import "BlogService.h"
#import "Blog.h"

#import "BlogListViewController.h"
#import "BlogDetailsViewController.h"
#import "WPScrollableViewController.h"
#import <WordPressShared/WPDeviceIdentification.h>
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"

@import Gridicons;
@import WordPressShared;

static NSString * const WPTabBarRestorationID = @"WPTabBarID";

static NSString * const WPReaderSplitViewRestorationID = @"WPReaderSplitViewRestorationID";
static NSString * const WPNotificationsSplitViewRestorationID = @"WPNotificationsSplitViewRestorationID";
static NSString * const WPMeSplitViewRestorationID = @"WPMeSplitViewRestorationID";

static NSString * const WPReaderNavigationRestorationID = @"WPReaderNavigationID";
static NSString * const WPMeNavigationRestorationID = @"WPMeNavigationID";
static NSString * const WPNotificationsNavigationRestorationID  = @"WPNotificationsNavigationID";
static NSString * const WPTabBarButtonClassname = @"UITabBarButton";

// used to restore the last selected tab bar item
static NSString * const WPTabBarSelectedIndexKey = @"WPTabBarSelectedIndexKey";

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

@interface WPTabBarController () <UITabBarControllerDelegate, UIViewControllerRestoration>

@property (nonatomic, assign) BOOL shouldUseStaticScreens;

@property (nonatomic, strong) NotificationsViewController *notificationsViewController;

@property (nonatomic, strong) UINavigationController *readerNavigationController;
@property (nonatomic, strong) UINavigationController *notificationsNavigationController;

@property (nonatomic, strong) MeViewController *meViewController;
@property (nonatomic, strong) UINavigationController *meNavigationController;

@property (nonatomic, strong) WPSplitViewController *notificationsSplitViewController;
@property (nonatomic, strong) WPSplitViewController *meSplitViewController;
@property (nonatomic, strong) ReaderTabViewModel *readerTabViewModel;

@property (nonatomic, strong, nullable) MySitesCoordinator *mySitesCoordinator;

@property (nonatomic, strong) UIImage *notificationsTabBarImage;
@property (nonatomic, strong) UIImage *notificationsTabBarImageUnread;
@property (nonatomic, strong) UIImage *meTabBarImage;
@property (nonatomic, strong) UIImage *meTabBarImageUnreadUnselected;
@property (nonatomic, strong) UIImage *meTabBarImageUnreadSelected;

@property (nonatomic, assign) CGFloat tabBarHeight;

@end

@implementation WPTabBarController

#pragma mark - Class methods

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self class] sharedInstance];
}

#pragma mark - Instance methods

- (instancetype)initWithStaticScreens:(BOOL)shouldUseStaticScreens
{
    self = [super init];
    if (self) {
        _shouldUseStaticScreens = shouldUseStaticScreens;
        [self setDelegate:self];
        [self setRestorationIdentifier:WPTabBarRestorationID];
        [self setRestorationClass:[WPTabBarController class]];
        [[self tabBar] setAccessibilityIdentifier:@"Main Navigation"];
        [[self tabBar] setAccessibilityLabel:NSLocalizedString(@"Main Navigation", nil)];
        [self setupColors];

        self.meScenePresenter = [[MeScenePresenter alloc] init];

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
                                                     name:WordPressAuthenticator.WPSigninDidFinishNotification
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
    [self stopWatchingQuickTours];
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:WPApplicationIconBadgeNumberKeyPath];
}

#pragma mark - UIViewControllerRestoration methods

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:self.selectedIndex forKey:WPTabBarSelectedIndexKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    self.selectedIndex = [coder decodeIntegerForKey:WPTabBarSelectedIndexKey];
    [super decodeRestorableStateWithCoder:coder];
}

#pragma mark - Tab Bar Items

- (UINavigationController *)readerNavigationController
{
    if (!_readerNavigationController) {
        UIViewController *rootViewController;
        if (self.shouldUseStaticScreens) {
            rootViewController = [[MovedToJetpackViewController alloc] initWithSource:MovedToJetpackSourceReader];
        } else {
            rootViewController = self.makeReaderTabViewController;
        }
        _readerNavigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
        _readerNavigationController.navigationBar.translucent = NO;
        _readerNavigationController.view.backgroundColor = [UIColor murielBasicBackground];

        if ([Feature enabled:FeatureFlagNewTabIcons]) {
            _readerNavigationController.tabBarItem.image = [[UIImage imageNamed:@"tab-bar-reader-unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            _readerNavigationController.tabBarItem.selectedImage = [UIImage imageNamed:@"tab-bar-reader-selected"];
        } else {
            UIImage *readerTabBarImage = [UIImage imageNamed:@"icon-tab-reader"];
            _readerNavigationController.tabBarItem.image = readerTabBarImage;
            _readerNavigationController.tabBarItem.selectedImage = readerTabBarImage;
        }
        _readerNavigationController.restorationIdentifier = WPReaderNavigationRestorationID;
        _readerNavigationController.tabBarItem.accessibilityIdentifier = @"readerTabButton";
        _readerNavigationController.tabBarItem.title = NSLocalizedString(@"Reader", @"The accessibility value of the Reader tab.");
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
    _notificationsNavigationController.navigationBar.translucent = NO;
    if ([Feature enabled:FeatureFlagNewTabIcons]) {
        self.notificationsTabBarImage = [[UIImage imageNamed:@"tab-bar-notifications-unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        NSString *unreadImageName = [AppConfiguration isJetpack] ? @"tab-bar-notifications-unread-jp" : @"tab-bar-notifications-unread-wp";
        self.notificationsTabBarImageUnread = [[UIImage imageNamed:unreadImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        _notificationsNavigationController.tabBarItem.image = self.notificationsTabBarImage;
        _notificationsNavigationController.tabBarItem.selectedImage = [UIImage imageNamed:@"tab-bar-notifications-selected"];
    } else {
        self.notificationsTabBarImage = [UIImage imageNamed:@"icon-tab-notifications"];
        NSString *unreadImageName = [AppConfiguration isJetpack] ? @"icon-tab-notifications-unread-jetpack" : @"icon-tab-notifications-unread";
        self.notificationsTabBarImageUnread = [[UIImage imageNamed:unreadImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        _notificationsNavigationController.tabBarItem.image = self.notificationsTabBarImage;
        _notificationsNavigationController.tabBarItem.selectedImage = self.notificationsTabBarImage;
    }
    _notificationsNavigationController.restorationIdentifier = WPNotificationsNavigationRestorationID;
    _notificationsNavigationController.tabBarItem.accessibilityIdentifier = @"notificationsTabButton";
    _notificationsNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    _notificationsNavigationController.tabBarItem.title = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");

    return _notificationsNavigationController;
}

- (UINavigationController *)meNavigationController
{
    if (!_meNavigationController) {
        _meNavigationController = [[UINavigationController alloc] initWithRootViewController:self.meViewController];
        if ([Feature enabled:FeatureFlagNewTabIcons]) {
            [self configureMeTabImageWithUnselectedPlaceholderImage:[[UIImage imageNamed:@"tab-bar-me-unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                           selectedPlaceholderImage:[UIImage imageNamed:@"tab-bar-me-selected"]];
        } else {
            [self configureMeTabImageWithPlaceholderImage:[UIImage imageNamed:@"icon-tab-me"]];
        }
        _meNavigationController.restorationIdentifier = WPMeNavigationRestorationID;
        _meNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Me", @"The accessibility value of the me tab.");
        _meNavigationController.tabBarItem.accessibilityIdentifier = @"meTabButton";
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

#pragma mark - Split View Controllers

- (ReaderTabViewModel *)readerTabViewModel
{
    if (!_readerTabViewModel) {
        _readerTabViewModel = [self makeReaderTabViewModel];
    }
    return _readerTabViewModel;
}

- (UISplitViewController *)notificationsSplitViewController
{
    if (!_notificationsSplitViewController) {
        _notificationsSplitViewController = [WPSplitViewController new];
        _notificationsSplitViewController.restorationIdentifier = WPNotificationsSplitViewRestorationID;
         [_notificationsSplitViewController setInitialPrimaryViewController:self.notificationsNavigationController];
        _notificationsSplitViewController.fullscreenDisplayEnabled = NO;
        _notificationsSplitViewController.wpPrimaryColumnWidth = WPSplitViewControllerPrimaryColumnWidthDefault;

        _notificationsSplitViewController.tabBarItem = self.notificationsNavigationController.tabBarItem;
    }

    return _notificationsSplitViewController;
}

- (UISplitViewController *)meSplitViewController
{
    if (!_meSplitViewController) {
        _meSplitViewController = [WPSplitViewController new];
        _meSplitViewController.restorationIdentifier = WPMeSplitViewRestorationID;
        [_meSplitViewController setInitialPrimaryViewController:self.meNavigationController];
        _meSplitViewController.fullscreenDisplayEnabled = NO;
        _meSplitViewController.wpPrimaryColumnWidth = WPSplitViewControllerPrimaryColumnWidthDefault;

        _meSplitViewController.tabBarItem = self.meNavigationController.tabBarItem;
    }

    return _meSplitViewController;
}

- (void)reloadSplitViewControllers
{
    _readerNavigationController = nil;
    _notificationsNavigationController = nil;
    _notificationsSplitViewController = nil;
    _meSplitViewController = nil;
    
    [self setViewControllers:[self tabViewControllers]];
    
    // Reset the selectedIndex to the default MySites tab.
    self.selectedIndex = WPTabMySites;
}

- (void)resetReaderTab
{
    _readerNavigationController = nil;
    [self setViewControllers:[self tabViewControllers]];
}

#pragma mark - Navigation Coordinators

- (MySitesCoordinator *)mySitesCoordinator
{
    if (!_mySitesCoordinator) {
        __weak __typeof(self) weakSelf = self;
        
        _mySitesCoordinator = [[MySitesCoordinator alloc] initWithMeScenePresenter: self.meScenePresenter
                                                                 onBecomeActiveTab:^{
            [weakSelf showMySitesTab];
        }];
    }
    
    return _mySitesCoordinator;
}

- (ReaderCoordinator *)readerCoordinator
{
    return [[ReaderCoordinator alloc] initWithReaderNavigationController:self.readerNavigationController];
}

#pragma mark - Navigation Helpers

- (NSArray<UIViewController *> *)tabViewControllers
{
    if (self.shouldUseStaticScreens) {
        return @[
            self.mySitesCoordinator.rootViewController,
            self.readerNavigationController,
            self.notificationsNavigationController,
            self.meSplitViewController
        ];
    }

    return @[
        self.mySitesCoordinator.rootViewController,
        self.readerNavigationController,
        self.notificationsSplitViewController,
        self.meSplitViewController
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

- (void)showReaderTabForPost:(NSNumber *)postId onBlog:(NSNumber *)blogId
{
    [self showReaderTab];
    UIViewController *topDetailVC = (UIViewController *)self.readerNavigationController.topViewController;

    // TODO: needed?
    if ([topDetailVC isKindOfClass:[ReaderDetailViewController class]]) {
        ReaderDetailViewController *readerDetailVC = (ReaderDetailViewController *)topDetailVC;
        ReaderPost *readerPost = readerDetailVC.post;
        if ([readerPost.postID isEqual:postId] && [readerPost.siteID isEqual: blogId]) {
         // The desired reader detail VC is already the top VC for the tab. Move along.
            return;
        }
    }
    
    UIViewController *readerPostDetailVC = [ReaderDetailViewController controllerWithPostID:postId siteID:blogId isFeed:NO];
    [self.readerNavigationController pushFullscreenViewController:readerPostDetailVC animated:YES];
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
        switch (selectedIndex) {
            case WPTabMySites: {
                break;
            }
            case WPTabReader: {
                [self alertQuickStartThatReaderWasTapped];
                break;
            }
            case WPTabNotifications: {
                [self alertQuickStartThatNotificationsWasTapped];
                break;
            }
            default: break;
        }

        [self trackTabAccessForTabIndex:selectedIndex];
        [self alertQuickStartThatOtherTabWasTapped];
    } else {
        // If the current view controller is selected already and it's at its root then scroll to the top
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navController = (UINavigationController *)viewController;
            [navController scrollContentToTopAnimated:YES];
        } else if ([viewController isKindOfClass:[WPSplitViewController class]]) {
            WPSplitViewController *splitViewController = (WPSplitViewController *)viewController;
            [splitViewController popToRootViewControllersAnimated:YES];
        }
    }

    return YES;
}

- (void)showNotificationsTabForNoteWithID:(NSString *)notificationID
{
    [self setSelectedIndex:WPTabNotifications];
    [self.notificationsViewController showDetailsForNotificationWithID:notificationID];
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
    [self reloadSplitViewControllers];
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
    showMySitesTabCommand.discoverabilityTitle = NSLocalizedString(@"Reader", @"The accessibility value of the reader tab.");
    
    UIKeyCommand *showNotificationsTabCommand = [UIKeyCommand keyCommandWithInput:@"4" modifierFlags:UIKeyModifierCommand action:@selector(showNotificationsTab)];
    showMySitesTabCommand.discoverabilityTitle = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    
    
    return @[showMySitesTabCommand, showReaderTabCommand, showNotificationsTabCommand];
}

#pragma mark - Handling Layout

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startObserversForTabAccessTracking];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateNotificationBadgeVisibility];
    [self startWatchingQuickTours];

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
