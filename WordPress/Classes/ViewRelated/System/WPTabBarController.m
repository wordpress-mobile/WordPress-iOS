#import "WPTabBarController.h"
#import <WordPressShared/UIImage+Util.h>

#import "WordPressAppDelegate.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "BlogService.h"
#import "Blog.h"

#import "BlogListViewController.h"
#import "BlogDetailsViewController.h"
#import "WPPostViewController.h"
#import "WPLegacyEditPageViewController.h"
#import "WPScrollableViewController.h"
#import "HelpshiftUtils.h"
#import "UIViewController+SizeClass.h"
#import <WordPressShared/WPDeviceIdentification.h>
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"

@import WordPressShared;

static NSString * const WPTabBarRestorationID = @"WPTabBarID";

static NSString * const WPBlogListSplitViewRestorationID = @"WPBlogListSplitViewRestorationID";
static NSString * const WPReaderSplitViewRestorationID = @"WPReaderSplitViewRestorationID";
static NSString * const WPMeSplitViewRestorationID = @"WPMeSplitViewRestorationID";
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

// Constants for the unread notification dot icon
static NSInteger const WPNotificationBadgeIconRadius = 5;
static NSInteger const WPNotificationBadgeIconBorder = 2;
static NSInteger const WPNotificationBadgeIconSize = (WPNotificationBadgeIconRadius + WPNotificationBadgeIconBorder) * 2;
static NSInteger const WPNotificationBadgeIconVerticalOffsetFromTop = 6;
static NSInteger const WPNotificationBadgeIconHorizontalOffsetFromCenter = 13;

static NSInteger const WPTabBarIconOffsetiPad = 7;
static NSInteger const WPTabBarIconOffsetiPhone = 5;

@interface WPTabBarController () <UITabBarControllerDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) BlogListViewController *blogListViewController;
@property (nonatomic, strong) NotificationsViewController *notificationsViewController;
@property (nonatomic, strong) ReaderMenuViewController *readerMenuViewController;
@property (nonatomic, strong) MeViewController *meViewController;
@property (nonatomic, strong) UIViewController *newPostViewController;

@property (nonatomic, strong) UINavigationController *blogListNavigationController;
@property (nonatomic, strong) UINavigationController *readerNavigationController;
@property (nonatomic, strong) UINavigationController *notificationsNavigationController;
@property (nonatomic, strong) UINavigationController *meNavigationController;

@property (nonatomic, strong) WPSplitViewController *blogListSplitViewController;
@property (nonatomic, strong) WPSplitViewController *readerSplitViewController;
@property (nonatomic, strong) WPSplitViewController *meSplitViewController;
@property (nonatomic, strong) WPSplitViewController *notificationsSplitViewController;

@property (nonatomic, strong) UIView *notificationBadgeIconView;

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
        [[self tabBar] setTranslucent:NO];
        [[self tabBar] setAccessibilityIdentifier:@"Main Navigation"];
        [[self tabBar] setAccessibilityLabel:NSLocalizedString(@"Main Navigation", nil)];
        // Create a background
        // (not strictly needed when white, but left here for possible customization)
        [[self tabBar] setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]]];

        [self setViewControllers:@[self.blogListSplitViewController,
                                   self.readerSplitViewController,
                                   self.newPostViewController,
                                   self.meSplitViewController,
                                   self.notificationsSplitViewController]];

        [self setSelectedViewController:self.blogListSplitViewController];

        // adds the orange dot on top of the notification tab
        [self addNotificationBadgeIcon];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(helpshiftUnreadCountUpdated:)
                                                     name:HelpshiftUnreadCountUpdatedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(defaultAccountDidChange:)
                                                     name:WPAccountDefaultWordPressComAccountChangedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(signinDidFinish:)
                                                     name:SigninHelpers.WPSigninDidFinishNotification
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] removeObserver:self forKeyPath:WPApplicationIconBadgeNumberKeyPath];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];

    // Bumping the stat in this method works for cases where the selected tab is
    // set in response to other feature behavior (e.g. a notifications), and
    // when set via state restoration.
    switch (selectedIndex) {
        case WPTabMe:
            [WPAppAnalytics track:WPAnalyticsStatMeTabAccessed];
            break;
        case WPTabMySites:
            [WPAppAnalytics track:WPAnalyticsStatMySitesTabAccessed];
            break;
        case WPTabReader:
            [WPAppAnalytics track:WPAnalyticsStatReaderAccessed];
            break;

        default:
            break;
    }
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

    self.blogListViewController = [[BlogListViewController alloc] init];
    _blogListNavigationController = [[UINavigationController alloc] initWithRootViewController:self.blogListViewController];
    _blogListNavigationController.navigationBar.translucent = NO;
    UIImage *mySitesTabBarImage = [UIImage imageNamed:@"icon-tab-mysites"];
    _blogListNavigationController.tabBarItem.image = [mySitesTabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    _blogListNavigationController.tabBarItem.selectedImage = mySitesTabBarImage;
    _blogListNavigationController.restorationIdentifier = WPBlogListNavigationRestorationID;
    _blogListNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"My Sites", @"The accessibility value of the my sites tab.");
    _blogListNavigationController.tabBarItem.accessibilityIdentifier = @"mySitesTabButton";
    _blogListNavigationController.tabBarItem.title = NSLocalizedString(@"My Sites", @"The accessibility value of the my sites tab.");

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
        _readerNavigationController = [[UINavigationController alloc] initWithRootViewController:self.readerMenuViewController];

        _readerNavigationController.navigationBar.translucent = NO;
        UIImage *readerTabBarImage = [UIImage imageNamed:@"icon-tab-reader"];
        _readerNavigationController.tabBarItem.image = [readerTabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        _readerNavigationController.tabBarItem.selectedImage = readerTabBarImage;
        _readerNavigationController.restorationIdentifier = WPReaderNavigationRestorationID;
        _readerNavigationController.tabBarItem.accessibilityIdentifier = @"readerTabButton";
        _readerNavigationController.tabBarItem.title = NSLocalizedString(@"Reader", @"The accessibility value of the Reader tab.");
    }

    return _readerNavigationController;
}

- (ReaderMenuViewController *)readerMenuViewController
{
    if (!_readerMenuViewController) {
        _readerMenuViewController = [ReaderMenuViewController controller];
    }

    return _readerMenuViewController;
}

- (UIViewController *)newPostViewController
{
    if (_newPostViewController) {
        return _newPostViewController;
    }

    UIImage *newPostImage = [UIImage imageNamed:@"icon-tab-newpost"];
    newPostImage = [newPostImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    _newPostViewController = [[UIViewController alloc] init];
    _newPostViewController.tabBarItem.image = newPostImage;
    _newPostViewController.tabBarItem.imageInsets = [self tabBarIconImageInsets];
    _newPostViewController.tabBarItem.accessibilityIdentifier = @"New Post";
    _newPostViewController.tabBarItem.title = NSLocalizedString(@"New Post", @"The accessibility value of the post tab.");
    _newPostViewController.tabBarItem.titlePositionAdjustment = UIOffsetMake(0, 20.0);

    return _newPostViewController;
}

- (UINavigationController *)meNavigationController
{
    if (!_meNavigationController) {
        _meNavigationController = [[UINavigationController alloc] initWithRootViewController:self.meViewController];
        UIImage *meTabBarImage = [UIImage imageNamed:@"icon-tab-me"];
        _meNavigationController.tabBarItem.image = [meTabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        _meNavigationController.tabBarItem.selectedImage = meTabBarImage;
        _meNavigationController.restorationIdentifier = WPMeNavigationRestorationID;
        _meNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Me", @"The accessibility value of the me tab.");
        _meNavigationController.tabBarItem.accessibilityIdentifier = @"meTabButton";
        _meNavigationController.tabBarItem.title = NSLocalizedString(@"Me", @"The accessibility value of the me tab.");
    }

    return _meNavigationController;
}

- (MeViewController *)meViewController {
    if (!_meViewController) {
        _meViewController = [MeViewController new];
    }

    return _meViewController;
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
    UIImage *notificationsTabBarImage = [UIImage imageNamed:@"icon-tab-notifications"];
    _notificationsNavigationController.tabBarItem.image = [notificationsTabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    _notificationsNavigationController.tabBarItem.selectedImage = notificationsTabBarImage;
    _notificationsNavigationController.restorationIdentifier = WPNotificationsNavigationRestorationID;
    _notificationsNavigationController.tabBarItem.accessibilityIdentifier = @"notificationsTabButton";
    _notificationsNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    _notificationsNavigationController.tabBarItem.title = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");

    return _notificationsNavigationController;
}

- (UIEdgeInsets)tabBarIconImageInsets
{
    CGFloat offset = [WPDeviceIdentification isiPad] ? WPTabBarIconOffsetiPad : WPTabBarIconOffsetiPhone;

    return UIEdgeInsetsMake(offset, 0, -offset, 0);
}

#pragma mark - Split View Controllers

- (UISplitViewController *)blogListSplitViewController
{
    if (!_blogListSplitViewController) {
        _blogListSplitViewController = [WPSplitViewController new];
        _blogListSplitViewController.restorationIdentifier = WPBlogListSplitViewRestorationID;
        _blogListSplitViewController.presentsWithGesture = NO;
        _blogListSplitViewController.wpPrimaryColumnWidth = WPSplitViewControllerPrimaryColumnWidthNarrow;

        [_blogListSplitViewController setInitialPrimaryViewController:self.blogListNavigationController];

        _blogListSplitViewController.dimsDetailViewControllerAutomatically = YES;

        _blogListSplitViewController.tabBarItem = self.blogListNavigationController.tabBarItem;
    }

    return _blogListSplitViewController;
}

- (UISplitViewController *)readerSplitViewController
{
    if (!_readerSplitViewController) {
        _readerSplitViewController = [WPSplitViewController new];
        _readerSplitViewController.restorationIdentifier = WPReaderSplitViewRestorationID;
        _readerSplitViewController.presentsWithGesture = NO;
        _readerSplitViewController.wpPrimaryColumnWidth = WPSplitViewControllerPrimaryColumnWidthNarrow;
        _readerSplitViewController.collapseMode = WPSplitViewControllerCollapseModeAlwaysKeepDetail;

        // There's currently a bug on Plus sized phones where the detail navigation
        // stack gets corrupted after restoring state: https://github.com/wordpress-mobile/WordPress-iOS/pull/6287#issuecomment-266877329
        // I've been unable to resolve it thus far, so for now we'll disable
        // landscape split view on Plus devices for the Reader.
        // James Frost 2017-01-09
         if ([WPDeviceIdentification isUnzoomediPhonePlus]) {
            [_readerSplitViewController setOverrideTraitCollection:[UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact]];
        }

        [_readerSplitViewController setInitialPrimaryViewController:self.readerNavigationController];

        _readerSplitViewController.tabBarItem = self.readerNavigationController.tabBarItem;
    }

    return _readerSplitViewController;
}

- (UISplitViewController *)meSplitViewController
{
    if (!_meSplitViewController) {
        _meSplitViewController = [WPSplitViewController new];
        _meSplitViewController.restorationIdentifier = WPMeSplitViewRestorationID;
        _meSplitViewController.wpPrimaryColumnWidth = WPSplitViewControllerPrimaryColumnWidthNarrow;

        [_meSplitViewController setInitialPrimaryViewController:self.meNavigationController];

        _meSplitViewController.tabBarItem = self.meNavigationController.tabBarItem;
    }
    
    return _meSplitViewController;
}

- (UISplitViewController *)notificationsSplitViewController
{
    if (!_notificationsSplitViewController) {
        _notificationsSplitViewController = [WPSplitViewController new];
        _notificationsSplitViewController.restorationIdentifier = WPNotificationsSplitViewRestorationID;
        _notificationsSplitViewController.fullscreenDisplayEnabled = NO;
        _notificationsSplitViewController.wpPrimaryColumnWidth = WPSplitViewControllerPrimaryColumnWidthDefault;

        [_notificationsSplitViewController setInitialPrimaryViewController:self.notificationsNavigationController];

        _notificationsSplitViewController.tabBarItem = self.notificationsNavigationController.tabBarItem;
    }

    return _notificationsSplitViewController;
}

- (void)reloadSplitViewControllers
{
    _blogListNavigationController = nil;
    _blogListSplitViewController = nil;
    _readerNavigationController = nil;
    _readerMenuViewController = nil;
    _readerSplitViewController = nil;
    _meSplitViewController = nil;
    _notificationsNavigationController = nil;
    _notificationsSplitViewController = nil;

    [self setViewControllers:@[self.blogListSplitViewController,
                               self.readerSplitViewController,
                               self.newPostViewController,
                               self.meSplitViewController,
                               self.notificationsSplitViewController]];

    // Bring the badge view to the front, while recreating the VCs the TabBarItems are
    // recreated too, leaving it in the back
    [self.tabBar bringSubviewToFront:self.notificationBadgeIconView];

    // Reset the selectedIndex to the default MySites tab.
    self.selectedIndex = WPTabMySites;
}

#pragma mark - Navigation Helpers

- (void)showTabForIndex:(NSInteger)tabIndex
{
    [self setSelectedIndex:tabIndex];
}

- (void)showMySitesTab
{
    [self showTabForIndex:WPTabMySites];
}

- (void)showReaderTab
{
    [self showTabForIndex:WPTabReader];
}

- (void)showPostTab
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    // Ignore taps on the post tab and instead show the modal.
    if ([blogService blogCountForAllAccounts] == 0) {
        [self switchMySitesTabToAddNewSite];
    } else {
        [self showPostTabAnimated:true toMedia:false];
    }
}

- (void)showMeTab
{
    [self showTabForIndex:WPTabMe];
}

- (void)showNotificationsTab
{
    [self showTabForIndex:WPTabNotifications];
}

- (void)showPostTabAnimated:(BOOL)animated toMedia:(BOOL)openToMedia
{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }

    Blog *blog = [self currentlyVisibleBlog];
    if (blog == nil) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
        blog = [blogService lastUsedOrFirstBlog];
    }

    EditPostViewController* editor = [[EditPostViewController alloc] initWithBlog:blog];
    editor.modalPresentationStyle = UIModalPresentationFullScreen;
    editor.showImmediately = !animated;
    editor.openWithMediaPicker = openToMedia;
    [WPAppAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{ @"tap_source": @"tab_bar"} withBlog:blog];
    [self presentViewController:editor animated:NO completion:nil];
    return;
}

- (void)showReaderTabForPost:(NSNumber *)postId onBlog:(NSNumber *)blogId
{
    ReaderMenuViewController *readerMenuViewController = (ReaderMenuViewController *)[self.readerNavigationController.viewControllers firstObject];
    if ([ReaderMenuViewController isKindOfClass:[ReaderMenuViewController class]]) {
        [self showReaderTab];
        [readerMenuViewController openPost:postId onBlog:blogId];
    }
}

- (void)switchTabToPostsListForPost:(AbstractPost *)post
{
    UIViewController *topVC = [self.blogListSplitViewController topDetailViewController];
    if ([topVC isKindOfClass:[PostListViewController class]]) {
        Blog *blog = ((PostListViewController *)topVC).blog;
        if ([post.blog.objectID isEqual:blog.objectID]) {
            // The desired post view controller is already the top viewController for the tab.
            // Nothing to see here.  Move along.
            return;
        }
    }

    [self switchMySitesTabToBlogDetailsForBlog:post.blog];

    BlogDetailsViewController *blogDetailVC = (BlogDetailsViewController *)self.blogListNavigationController.topViewController;
    if ([blogDetailVC isKindOfClass:[BlogDetailsViewController class]]) {
        [blogDetailVC showDetailViewForSubsection:BlogDetailsSubsectionPosts];
    }
}

- (void)switchMySitesTabToAddNewSite
{
    [self showTabForIndex:WPTabMySites];
    [self.blogListViewController presentInterfaceForAddingNewSite];
}

- (void)switchMySitesTabToStatsViewForBlog:(Blog *)blog
{
    [self switchMySitesTabToBlogDetailsForBlog:blog];

    BlogDetailsViewController *blogDetailVC = (BlogDetailsViewController *)self.blogListNavigationController.topViewController;
    if ([blogDetailVC isKindOfClass:[BlogDetailsViewController class]]) {
        [blogDetailVC showDetailViewForSubsection:BlogDetailsSubsectionStats];
    }
}

- (void)switchMySitesTabToCustomizeViewForBlog:(Blog *)blog
{
    [self switchMySitesTabToThemesViewForBlog:blog];

    UIViewController *topVC = [self.blogListSplitViewController topDetailViewController];
    if ([topVC isKindOfClass:[ThemeBrowserViewController class]]) {
        ThemeBrowserViewController *themeViewController = (ThemeBrowserViewController *)topVC;
        [themeViewController presentCustomizeForTheme:[themeViewController currentTheme]];
    }
}

- (void)switchMySitesTabToThemesViewForBlog:(Blog *)blog
{
    [self switchMySitesTabToBlogDetailsForBlog:blog];

    BlogDetailsViewController *blogDetailVC = (BlogDetailsViewController *)self.blogListNavigationController.topViewController;
    if ([blogDetailVC isKindOfClass:[BlogDetailsViewController class]]) {
        [blogDetailVC showDetailViewForSubsection:BlogDetailsSubsectionThemes];
    }
}

- (void)switchMySitesTabToBlogDetailsForBlog:(Blog *)blog
{
    [self showTabForIndex:WPTabMySites];

    BlogListViewController *blogListVC = self.blogListViewController;
    self.blogListNavigationController.viewControllers = @[blogListVC];
    [blogListVC setSelectedBlog:blog animated:NO];
}

- (NSString *)currentlySelectedScreen
{
    // Check which tab is currently selected
    NSString *currentlySelectedScreen = @"";
    switch (self.selectedIndex) {
        case WPTabMySites:
            currentlySelectedScreen = @"Blog List";
            break;
        case WPTabReader:
            currentlySelectedScreen = @"Reader";
            break;
        case WPTabNotifications:
            currentlySelectedScreen = @"Notifications";
            break;
        case WPTabMe:
            currentlySelectedScreen = @"Me";
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

#pragma mark - UITabBarControllerDelegate methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    NSUInteger newIndex = [tabBarController.viewControllers indexOfObject:viewController];

    if (newIndex == WPTabNewPost) {
        [self showPostTab];
        return NO;
    }

    // If we're selecting a new tab...
    if (newIndex != tabBarController.selectedIndex) {
        switch (newIndex) {
            case WPTabMySites: {
                [WPAppAnalytics track:WPAnalyticsStatMySitesTabAccessed];
                [self bypassBlogListViewControllerIfNecessary];
                break;
            }
            case WPTabReader: {
                [WPAppAnalytics track:WPAnalyticsStatReaderAccessed];
                break;
            }
            case WPTabMe: {
                [WPAppAnalytics track:WPAnalyticsStatMeTabAccessed];
                break;
            }
            default: break;
        }
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
    [self showTabForIndex:WPTabNotifications];
    [self.notificationsViewController showDetailsForNotificationWithID:notificationID];
}

- (BOOL)isNavigatingMySitesTab
{
    return (self.selectedIndex == WPTabMySites && [self.blogListViewController.navigationController.viewControllers count] > 1);
}

#pragma mark - Helpshift Notifications

- (void)helpshiftUnreadCountUpdated:(NSNotification *)notification
{
    NSInteger unreadCount = [HelpshiftUtils unreadNotificationCount];
    UITabBarItem *meTabBarItem = self.tabBar.items[WPTabMe];
    if (unreadCount == 0) {
        [meTabBarItem setBadgeValue:nil];
    }
    else {
        [meTabBarItem setBadgeValue:[NSString stringWithFormat:@"%ld", unreadCount]];
    }
}

#pragma mark - Default Account Notifications

- (void)defaultAccountDidChange:(NSNotification *)notification
{
    if (notification.object == nil) {
        [self.readerNavigationController popToRootViewControllerAnimated:NO];
        [self.meNavigationController popToRootViewControllerAnimated:NO];
        [self.notificationsNavigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)signinDidFinish:(NSNotification *)notification
{
    [self reloadSplitViewControllers];
}

#pragma mark - Handling Badges

- (void)updateNotificationBadgeVisibility
{
    NSInteger count = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    UITabBarItem *tabBarItem = self.notificationsNavigationController.tabBarItem;
    if (count == 0) {
        self.notificationBadgeIconView.hidden = YES;
        tabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
        return;
    }

    // When the user logs in the VCs are recreated and at the time viewDidLayoutSubviews is
    // invoked the TabButton frames are not correct, so we need to recalculate the badge position
    [self updateNotificationBadgeIconPosition];
    BOOL wasNotificationBadgeHidden = self.notificationBadgeIconView.hidden;
    self.notificationBadgeIconView.hidden = NO;
    tabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications Unread", @"Notifications tab bar item accessibility label, unread notifications state");
    if (wasNotificationBadgeHidden) {
        [self animateNotificationBadgeIcon];
    }
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
             [UIKeyCommand keyCommandWithInput:@"N" modifierFlags:UIKeyModifierCommand action:@selector(showPostTab) discoverabilityTitle:NSLocalizedString(@"New Post", @"The accessibility value of the post tab.")],
             [UIKeyCommand keyCommandWithInput:@"1" modifierFlags:UIKeyModifierCommand action:@selector(showMySitesTab) discoverabilityTitle:NSLocalizedString(@"My Sites", @"The accessibility value of the my sites tab.")],
             [UIKeyCommand keyCommandWithInput:@"2" modifierFlags:UIKeyModifierCommand action:@selector(showReaderTab) discoverabilityTitle:NSLocalizedString(@"Reader", @"The accessibility value of the reader tab.")],
             [UIKeyCommand keyCommandWithInput:@"3" modifierFlags:UIKeyModifierCommand action:@selector(showMeTab) discoverabilityTitle:NSLocalizedString(@"Me", @"The accessibility value of the me tab.")],
             [UIKeyCommand keyCommandWithInput:@"4" modifierFlags:UIKeyModifierCommand action:@selector(showNotificationsTab) discoverabilityTitle:NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label")],
             ];
}

#pragma mark - Notification Badge Icon Management

- (void)addNotificationBadgeIcon
{
    CGRect badgeFrame = CGRectMake(0, 0, WPNotificationBadgeIconSize, WPNotificationBadgeIconSize);
    self.notificationBadgeIconView = [[UIView alloc] initWithFrame:badgeFrame];
    
    CAShapeLayer *badgeLayer = [CAShapeLayer layer];
    badgeLayer.contentsScale = [UIScreen mainScreen].scale;
    CGPoint badgeCenter = CGPointMake(WPNotificationBadgeIconSize / 2.f, WPNotificationBadgeIconSize / 2.f);
    CGFloat badgeRadius = WPNotificationBadgeIconRadius + WPNotificationBadgeIconBorder / 2.f;
    badgeLayer.path = [UIBezierPath bezierPathWithArcCenter:badgeCenter radius:badgeRadius startAngle:0 endAngle:M_PI * 2 clockwise:NO].CGPath;
    badgeLayer.fillColor = [WPStyleGuide jazzyOrange].CGColor;
    badgeLayer.strokeColor = [UIColor whiteColor].CGColor;
    badgeLayer.lineWidth = WPNotificationBadgeIconBorder;
    [self.notificationBadgeIconView.layer addSublayer:badgeLayer];

    self.notificationBadgeIconView.hidden = YES;
    [self.tabBar addSubview:self.notificationBadgeIconView];
}

- (void)updateNotificationBadgeIconPosition
{
    CGRect notificationsButtonFrame = [self notificationsButtonFrame];
    CGRect rect = self.notificationBadgeIconView.frame;
    rect.origin.y = WPNotificationBadgeIconVerticalOffsetFromTop;
    rect.origin.x = CGRectGetMidX(notificationsButtonFrame) - WPNotificationBadgeIconHorizontalOffsetFromCenter;
    self.notificationBadgeIconView.frame = rect;
}

- (void)animateNotificationBadgeIcon
{
    // Note:
    // We need to force a layout pass (*if needed*) right now. Otherwise, the view may get layed out
    // at the middle of the animation, which may lead to inconsistencies.
    //
    [self.view layoutIfNeeded];
    
    // Scotty, beam me up!
    //
    __weak __typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.notificationBadgeIconView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    } completion:^(BOOL finished) {
        if (!finished) {
            weakSelf.notificationBadgeIconView.transform = CGAffineTransformIdentity;
            return;
        }

        [UIView animateWithDuration:0.3 animations:^{
            weakSelf.notificationBadgeIconView.transform = CGAffineTransformMakeScale(0.85, 0.85);
        } completion:^(BOOL finished) {
            if (!finished) {
                weakSelf.notificationBadgeIconView.transform = CGAffineTransformIdentity;
                return;
            }

            [UIView animateWithDuration:0.2 animations:^{
                weakSelf.notificationBadgeIconView.transform = CGAffineTransformIdentity;
            }];
        }];
    }];
}

- (CGRect)lastTabBarButtonFrame
{
    // Hack:
    // In this method, we determine the UITabBarController's last button frame.
    // It's proven to be effective in *all* of the available devices to date, even in multitasking mode.
    // Even better, we don't even need one constant per device.
    //
    // On iOS 10, the first time this viewcontroller's view is laid out the tab bar buttons have
    // a zero origin, so this method can't choose a frame. On subsequent layout passes, the
    // buttons seem to have a correct frame, so this method still works for now.
    // (When this viewcontroller's view is first created, `viewDidLayoutSubviews` is called twice -
    // The second time has the correct frame).
    //
    CGRect lastButtonRect = CGRectZero;
    
    for (UIView *subview in self.tabBar.subviews) {
        if ([WPTabBarButtonClassname isEqualToString:NSStringFromClass([subview class])]) {
            if (CGRectGetMinX(subview.frame) > CGRectGetMinX(lastButtonRect)) {
                lastButtonRect = subview.frame;
            }
        }
    }
    
    return lastButtonRect;
}

- (CGRect)firstTabBarButtonFrame
{
    CGRect firstButtonRect = CGRectInfinite;

    for (UIView *subview in self.tabBar.subviews) {
        if ([WPTabBarButtonClassname isEqualToString:NSStringFromClass([subview class])]) {
            if (CGRectGetMaxX(subview.frame) < CGRectGetMaxX(firstButtonRect)) {
                firstButtonRect = subview.frame;
            }
        }
    }

    return firstButtonRect;
}

- (CGRect)notificationsButtonFrame
{
    if ([self.view userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionLeftToRight) {
        return [self lastTabBarButtonFrame];
    } else {
        return [self firstTabBarButtonFrame];
    }
}

#pragma mark - Handling Layout

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateNotificationBadgeVisibility];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateNotificationBadgeIconPosition];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    __weak __typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                                                [weakSelf updateNotificationBadgeIconPosition];
                                            }
                                 completion:nil];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    __weak __typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                                                [weakSelf updateNotificationBadgeIconPosition];
                                            }
                                 completion:nil];
}

// this class allows this VC to be a valid unwind destination for this selector
- (IBAction)unwindOutWithSegue:(UIStoryboardSegue *)segue
{
    // unwind segues don't seem to always clean themselves up 😫
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
