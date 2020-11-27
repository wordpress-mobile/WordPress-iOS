#import "WPTabBarController.h"
#import <WordPressUI/UIImage+Util.h>

#import "AccountService.h"
#import "ContextManager.h"
#import "BlogService.h"
#import "Blog.h"

#import "BlogListViewController.h"
#import "BlogDetailsViewController.h"
#import "WPScrollableViewController.h"
#import <WordPressShared/WPDeviceIdentification.h>
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"
#import "AMScrollingNavbar-Swift.h"

@import Gridicons;
@import WordPressShared;

static NSString * const WPTabBarRestorationID = @"WPTabBarID";

static NSString * const WPBlogListSplitViewRestorationID = @"WPBlogListSplitViewRestorationID";
static NSString * const WPReaderSplitViewRestorationID = @"WPReaderSplitViewRestorationID";
static NSString * const WPNotificationsSplitViewRestorationID = @"WPNotificationsSplitViewRestorationID";

static NSString * const WPBlogListNavigationRestorationID = @"WPBlogListNavigationID";
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

static NSInteger const WPTabBarIconOffsetiPad = 7;
static NSInteger const WPTabBarIconOffsetiPhone = 5;

@interface WPTabBarController () <UITabBarControllerDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) BlogListViewController *blogListViewController;
@property (nonatomic, strong) NotificationsViewController *notificationsViewController;

@property (nonatomic, strong) UINavigationController *blogListNavigationController;
@property (nonatomic, strong) UINavigationController *readerNavigationController;
@property (nonatomic, strong) UINavigationController *notificationsNavigationController;

@property (nonatomic, strong) WPSplitViewController *blogListSplitViewController;
@property (nonatomic, strong) WPSplitViewController *notificationsSplitViewController;
@property (nonatomic, strong) ReaderTabViewModel *readerTabViewModel;

@property (nonatomic, strong) UIImage *notificationsTabBarImage;
@property (nonatomic, strong) UIImage *notificationsTabBarImageUnread;
@property (nonatomic, strong) UIImage *meTabBarImage;
@property (nonatomic, strong) UIImage *meTabBarImageUnreadUnselected;
@property (nonatomic, strong) UIImage *meTabBarImageUnreadSelected;

@end

@implementation WPTabBarController

#pragma mark - Class methods

+ (instancetype)sharedInstance
{
    static WPTabBarController *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self class] sharedInstance];
}

#pragma mark - Instance methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setDelegate:self];
        [self setRestorationIdentifier:WPTabBarRestorationID];
        [self setRestorationClass:[WPTabBarController class]];
        [[self tabBar] setAccessibilityIdentifier:@"Main Navigation"];
        [[self tabBar] setAccessibilityLabel:NSLocalizedString(@"Main Navigation", nil)];
        [self setupColors];

        self.meScenePresenter = [[MeScenePresenter alloc] init];

        [self setViewControllers:[self tabViewControllers]];

        [self setSelectedViewController:self.blogListSplitViewController];
        
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
    }
    return self;
}

- (void)dealloc
{
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

- (UINavigationController *)blogListNavigationController
{
    if (_blogListNavigationController) {
        return _blogListNavigationController;
    }

    self.blogListViewController = [[BlogListViewController alloc] initWithMeScenePresenter:self.meScenePresenter];
    _blogListNavigationController = [[UINavigationController alloc] initWithRootViewController:self.blogListViewController];
    _blogListNavigationController.navigationBar.translucent = NO;

    UIImage *mySitesTabBarImage = [UIImage imageNamed:@"icon-tab-mysites"];
    _blogListNavigationController.tabBarItem.image = mySitesTabBarImage;
    _blogListNavigationController.tabBarItem.selectedImage = mySitesTabBarImage;
    _blogListNavigationController.restorationIdentifier = WPBlogListNavigationRestorationID;
    _blogListNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"My Site", @"The accessibility value of the my site tab.");
    _blogListNavigationController.tabBarItem.accessibilityIdentifier = @"mySitesTabButton";
    _blogListNavigationController.tabBarItem.title = NSLocalizedString(@"My Site", @"The accessibility value of the my site tab.");

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    Blog *blogToOpen = [blogService lastUsedOrFirstBlog];
    if (blogToOpen) {
        _blogListViewController.selectedBlog = blogToOpen;
    }
    
    return _blogListNavigationController;
}

- (UINavigationController *)readerNavigationController
{
    if (!_readerNavigationController) {
        _readerNavigationController = [[UINavigationController alloc] initWithRootViewController:self.makeReaderTabViewController];
        _readerNavigationController.navigationBar.translucent = NO;

        UIImage *readerTabBarImage = [UIImage imageNamed:@"icon-tab-reader"];
        _readerNavigationController.tabBarItem.image = readerTabBarImage;
        _readerNavigationController.tabBarItem.selectedImage = readerTabBarImage;
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

    UIStoryboard *notificationsStoryboard = [UIStoryboard storyboardWithName:@"Notifications" bundle:nil];
    self.notificationsViewController = [notificationsStoryboard instantiateInitialViewController];
    _notificationsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.notificationsViewController];
    _notificationsNavigationController.navigationBar.translucent = NO;
    self.notificationsTabBarImage = [UIImage imageNamed:@"icon-tab-notifications"];
    self.notificationsTabBarImageUnread = [[UIImage imageNamed:@"icon-tab-notifications-unread"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    _notificationsNavigationController.tabBarItem.image = self.notificationsTabBarImage;
    _notificationsNavigationController.tabBarItem.selectedImage = self.notificationsTabBarImage;
    _notificationsNavigationController.restorationIdentifier = WPNotificationsNavigationRestorationID;
    _notificationsNavigationController.tabBarItem.accessibilityIdentifier = @"notificationsTabButton";
    _notificationsNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    _notificationsNavigationController.tabBarItem.title = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");

    return _notificationsNavigationController;
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

- (UISplitViewController *)blogListSplitViewController
{
    if (!_blogListSplitViewController) {
        _blogListSplitViewController = [WPSplitViewController new];
        _blogListSplitViewController.restorationIdentifier = WPBlogListSplitViewRestorationID;
        _blogListSplitViewController.presentsWithGesture = NO;
        [_blogListSplitViewController setInitialPrimaryViewController:self.blogListNavigationController];
        _blogListSplitViewController.wpPrimaryColumnWidth = WPSplitViewControllerPrimaryColumnWidthNarrow;

        _blogListSplitViewController.dimsDetailViewControllerAutomatically = YES;

        _blogListSplitViewController.tabBarItem = self.blogListNavigationController.tabBarItem;
    }

    return _blogListSplitViewController;
}

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

- (void)reloadSplitViewControllers
{
    _blogListNavigationController = nil;
    _blogListSplitViewController = nil;
    _readerNavigationController = nil;
    _notificationsNavigationController = nil;
    _notificationsSplitViewController = nil;
    
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
    __weak __typeof(self) weakSelf = self;
    
    return [[MySitesCoordinator alloc] initWithMySitesSplitViewController:self.blogListSplitViewController
                                              mySitesNavigationController:self.blogListNavigationController
                                                   blogListViewController:self.blogListViewController
                                                        onBecomeActiveTab:^{
        [weakSelf showMySitesTab];
    }];
}

- (ReaderCoordinator *)readerCoordinator
{
    return [[ReaderCoordinator alloc] initWithReaderNavigationController:self.readerNavigationController];
}

#pragma mark - Navigation Helpers

- (NSArray<UIViewController *> *)tabViewControllers
{
    return @[self.blogListSplitViewController,
             self.readerNavigationController,
             self.notificationsSplitViewController];
}

- (void)showMySitesTab
{
    [self setSelectedIndex:WPTabMySites];
}

- (void)showReaderTab
{
    [self setSelectedIndex:WPTabReader];
}

- (void)showPostTab
{
    [self showPostTabWithCompletion:nil];
}

- (void)showPostTabWithCompletion:(void (^)(void))afterDismiss
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    // Ignore taps on the post tab and instead show the modal.
    if ([blogService blogCountForAllAccounts] == 0) {
        [self switchMySitesTabToAddNewSite];
    } else {
        [self showPostTabAnimated:true toMedia:false blog:nil afterDismiss:afterDismiss];
    }
}

- (void)showPostTabForBlog:(Blog *)blog
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    if ([blogService blogCountForAllAccounts] == 0) {
        [self switchMySitesTabToAddNewSite];
    } else {
        [self showPostTabAnimated:YES toMedia:NO blog:blog];
    }
}

- (void)showNotificationsTab
{
    [self setSelectedIndex:WPTabNotifications];
}

- (void)showPostTabAnimated:(BOOL)animated toMedia:(BOOL)openToMedia
{
    [self showPostTabAnimated:animated toMedia:openToMedia blog:nil];
}

- (void)showPostTabAnimated:(BOOL)animated toMedia:(BOOL)openToMedia blog:(Blog *)blog
{
    [self showPostTabAnimated:animated toMedia:openToMedia blog:blog afterDismiss:nil];
}

- (void)showPostTabAnimated:(BOOL)animated toMedia:(BOOL)openToMedia blog:(Blog *)blog afterDismiss:(void (^)(void))afterDismiss
{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }

    if (!blog) {
        blog = [self currentOrLastBlog];
    }

    EditPostViewController* editor = [[EditPostViewController alloc] initWithBlog:blog];
    editor.modalPresentationStyle = UIModalPresentationFullScreen;
    editor.showImmediately = !animated;
    editor.openWithMediaPicker = openToMedia;
    editor.afterDismiss = afterDismiss;
    
    NSString *tapSource = @"create_button";
    [WPAppAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{ WPAppAnalyticsKeyTapSource: tapSource, WPAppAnalyticsKeyPostType: @"post"} withBlog:blog];
    [self presentViewController:editor animated:NO completion:nil];
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

- (void)switchMySitesTabToAddNewSite
{
    [self setSelectedIndex:WPTabMySites];
    [self.blogListViewController presentInterfaceForAddingNewSiteFrom:self.tabBar];
}

- (void)switchMySitesTabToStatsViewForBlog:(Blog *)blog
{
    [self.mySitesCoordinator showBlogDetailsFor:blog];

    BlogDetailsViewController *blogDetailVC = (BlogDetailsViewController *)self.blogListNavigationController.topViewController;
    if ([blogDetailVC isKindOfClass:[BlogDetailsViewController class]]) {
        [blogDetailVC showDetailViewForSubsection:BlogDetailsSubsectionStats];
    }
}

- (void)switchMySitesTabToMediaForBlog:(Blog *)blog
{
    [self switchMySitesTabToBlogDetailsForBlog:blog];

    BlogDetailsViewController *blogDetailVC = (BlogDetailsViewController *)self.blogListNavigationController.topViewController;
    if ([blogDetailVC isKindOfClass:[BlogDetailsViewController class]]) {
        [blogDetailVC showDetailViewForSubsection:BlogDetailsSubsectionMedia];
    }
}
 
- (void)switchMySitesTabToBlogDetailsForBlog:(Blog *)blog
{
    [self setSelectedIndex:WPTabMySites];

    BlogListViewController *blogListVC = self.blogListViewController;
    self.blogListNavigationController.viewControllers = @[blogListVC];
    [blogListVC setSelectedBlog:blog animated:NO];
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

- (Blog *)currentlyVisibleBlog
{
    if (self.selectedIndex != WPTabMySites) {
        return nil;
    }

    BlogDetailsViewController *blogDetailsController = (BlogDetailsViewController *)[[self.blogListNavigationController.viewControllers wp_filter:^BOOL(id obj) {
        return [obj isKindOfClass:[BlogDetailsViewController class]];
    }] firstObject];
    return blogDetailsController.blog;
}

- (Blog *)currentOrLastBlog
{
    Blog *blog = [self currentlyVisibleBlog];

    if (blog == nil) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
        blog = [blogService lastUsedOrFirstBlog];
    }
    
    return blog;
}

#pragma mark - UITabBarControllerDelegate methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    NSUInteger selectedIndex = [tabBarController.viewControllers indexOfObject:viewController];

    // If we're selecting a new tab...
    if (selectedIndex != tabBarController.selectedIndex) {
        switch (selectedIndex) {
            case WPTabMySites: {
                [self bypassBlogListViewControllerIfNecessary];
                break;
            }
            case WPTabReader: {
                [self alertQuickStartThatReaderWasTapped];
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

- (void)bypassBlogListViewControllerIfNecessary
{
    // If the user has one blog then we don't want to present them with the main "My Sites"
    // screen where they can see all their blogs. In the case of only one blog just show
    // the main blog details screen
    UINavigationController *navController = (UINavigationController *)[self.blogListSplitViewController.viewControllers firstObject];
    BlogListViewController *blogListViewController = (BlogListViewController *)[navController.viewControllers firstObject];

    if ([blogListViewController shouldBypassBlogListViewControllerWhenSelectedFromTabBar]) {
        if ([navController.visibleViewController isKindOfClass:[blogListViewController class]]) {
            [blogListViewController bypassBlogListViewController];
        }
    }
}

- (void)showNotificationsTabForNoteWithID:(NSString *)notificationID
{
    [self setSelectedIndex:WPTabNotifications];
    [self.notificationsViewController showDetailsForNotificationWithID:notificationID];
}

- (BOOL)isNavigatingMySitesTab
{
    return (self.selectedIndex == WPTabMySites && [self.blogListViewController.navigationController.viewControllers count] > 1);
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
    // Discount Zendesk unread notifications when determining if we need to show the notificationsTabBarImageUnread.
    NSInteger count = [[UIApplication sharedApplication] applicationIconBadgeNumber] - [ZendeskUtils unreadNotificationsCount];
    UITabBarItem *notificationsTabBarItem = self.notificationsNavigationController.tabBarItem;
    if (count > 0 || ![self welcomeNotificationSeen]) {
        notificationsTabBarItem.image = self.notificationsTabBarImageUnread;
        notificationsTabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications Unread", @"Notifications tab bar item accessibility label, unread notifications state");
    } else {
        notificationsTabBarItem.image = self.notificationsTabBarImage;
        notificationsTabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    }

    if( UIApplication.sharedApplication.isCreatingScreenshots ) {
        notificationsTabBarItem.image = self.notificationsTabBarImage;
        notificationsTabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    }
}

- (void) showReaderBadge:(NSNotification *)notification
{
    UIImage *readerTabBarImage = [[UIImage imageNamed:@"icon-tab-reader-unread"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.readerNavigationController.tabBarItem.image = readerTabBarImage;

    if( UIApplication.sharedApplication.isCreatingScreenshots ) {
        [self hideReaderBadge:nil];
    }
}

-(BOOL) welcomeNotificationSeen
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSString *welcomeNotificationSeenKey = standardUserDefaults.welcomeNotificationSeenKey;
    return [standardUserDefaults boolForKey: welcomeNotificationSeenKey];
}

- (void) hideReaderBadge:(NSNotification *)notification
{
    UIImage *readerTabBarImage = [UIImage imageNamed:@"icon-tab-reader"];
    self.readerNavigationController.tabBarItem.image = readerTabBarImage;
}

#pragma mark - NSObject(NSKeyValueObserving) Helpers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:WPApplicationIconBadgeNumberKeyPath]) {
        [self updateNotificationBadgeVisibility];
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

    return @[
             [UIKeyCommand keyCommandWithInput:@"1" modifierFlags:UIKeyModifierCommand action:@selector(showMySitesTab) discoverabilityTitle:NSLocalizedString(@"My Site", @"The accessibility value of the my site tab.")],
             [UIKeyCommand keyCommandWithInput:@"2" modifierFlags:UIKeyModifierCommand action:@selector(showReaderTab) discoverabilityTitle:NSLocalizedString(@"Reader", @"The accessibility value of the reader tab.")],
             [UIKeyCommand keyCommandWithInput:@"4" modifierFlags:UIKeyModifierCommand action:@selector(showNotificationsTab) discoverabilityTitle:NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label")],
             ];
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

#pragma mark - What's New Presentation
- (id<ScenePresenter>)whatIsNewScenePresenter
{
    if (_whatIsNewScenePresenter) {
        return _whatIsNewScenePresenter;
    }
    self.whatIsNewScenePresenter = [self makeWhatIsNewPresenter];
    return _whatIsNewScenePresenter;
}

@end
