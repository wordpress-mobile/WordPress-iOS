#import "WPTabBarController.h"
#import <WordPressUI/UIImage+Util.h>

#import "WordPressAppDelegate.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "BlogService.h"
#import "Blog.h"

#import "BlogListViewController.h"
#import "BlogDetailsViewController.h"
#import "WPScrollableViewController.h"
#import "HelpshiftUtils.h"
#import <WordPressShared/WPDeviceIdentification.h>
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"

@import Gridicons;
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

static NSInteger const WPTabBarIconOffsetiPad = 7;
static NSInteger const WPTabBarIconOffsetiPhone = 5;
static CGFloat const WPTabBarIconSize = 32.0f;

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

@property (nonatomic, strong) UIImage *notificationsTabBarImage;
@property (nonatomic, strong) UIImage *notificationsTabBarImageUnread;

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

        // This can't be set using UIAppearance, otherwise it overrides the titleTextAttributes
        // set for unselected items.
        [[self tabBar] setUnselectedItemTintColor:[WPStyleGuide greyLighten10]];

        [self setViewControllers:@[self.blogListSplitViewController,
                                   self.readerSplitViewController,
                                   self.newPostViewController,
                                   self.meSplitViewController,
                                   self.notificationsSplitViewController]];

        [self setSelectedViewController:self.blogListSplitViewController];

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
    _blogListNavigationController.tabBarItem.image = mySitesTabBarImage;
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
        _readerNavigationController.tabBarItem.image = readerTabBarImage;
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

    _newPostViewController = [[UIViewController alloc] init];
    _newPostViewController.tabBarItem.accessibilityIdentifier = @"Write";
    _newPostViewController.tabBarItem.title = NSLocalizedString(@"Write", @"The accessibility value of the post tab.");

    [self updateWriteButtonAppearance];

    return _newPostViewController;
}

- (UINavigationController *)meNavigationController
{
    if (!_meNavigationController) {
        _meNavigationController = [[UINavigationController alloc] initWithRootViewController:self.meViewController];
        UIImage *meTabBarImage = [UIImage imageNamed:@"icon-tab-me"];
        _meNavigationController.tabBarItem.image = meTabBarImage;
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

- (void)updateWriteButtonAppearance
{
    CGSize size = self.view.bounds.size;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;

    // Try and determine whether the app is displayed at a size which will result in a tab
    // bar with button titles and images horizontally stacked, instead of vertically
    BOOL iPhoneLandscape = [WPDeviceIdentification isiPhone] && UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
    BOOL iPadPortraitFullscreen = [WPDeviceIdentification isiPad] &&
    UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) &&
    size.width == screenWidth;
    BOOL iPadLandscapeGreaterThanHalfSplit = [WPDeviceIdentification isiPad] &&
    UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) &&
    size.width > screenWidth / 2;

    if (iPhoneLandscape || iPadPortraitFullscreen || iPadLandscapeGreaterThanHalfSplit) {
        self.newPostViewController.tabBarItem.imageInsets = UIEdgeInsetsZero;
        self.newPostViewController.tabBarItem.titlePositionAdjustment = UIOffsetZero;
        self.newPostViewController.tabBarItem.image = [Gridicon iconOfType:GridiconTypeCreate withSize:CGSizeMake(WPTabBarIconSize, WPTabBarIconSize)];
    } else {
        self.newPostViewController.tabBarItem.imageInsets = [self tabBarIconImageInsets];
        self.newPostViewController.tabBarItem.titlePositionAdjustment = UIOffsetMake(0, 99999.0);

        self.newPostViewController.tabBarItem.image = [UIImage imageNamed:@"icon-tab-newpost"];
    }
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
    [self showReaderTab];

    UIViewController *topDetailVC = (ReaderDetailViewController *)self.readerSplitViewController.topDetailViewController;
    if ([topDetailVC isKindOfClass:[ReaderDetailViewController class]]) {
        ReaderDetailViewController *readerDetailVC = (ReaderDetailViewController *)topDetailVC;
        ReaderPost *readerPost = readerDetailVC.post;
        if ([readerPost.postID isEqual:postId] && [readerPost.siteID isEqual: blogId]) {
             // The desired reader detail VC is already the top VC for the tab. Move along.
            return;
        }
    }

    if (topDetailVC && topDetailVC.navigationController) {
        ReaderDetailViewController *readerPostDetailVC = [ReaderDetailViewController controllerWithPostID:postId siteID:blogId];
        [topDetailVC.navigationController pushFullscreenViewController:readerPostDetailVC animated:YES];
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

- (void)switchTabToPagesListForPost:(AbstractPost *)post
{
    UIViewController *topVC = [self.blogListSplitViewController topDetailViewController];
    if ([topVC isKindOfClass:[PageListViewController class]]) {
        Blog *blog = ((PageListViewController *)topVC).blog;
        if ([post.blog.objectID isEqual:blog.objectID]) {
            // The desired post view controller is already the top viewController for the tab.
            // Nothing to see here.  Move along.
            return;
        }
    }

    [self switchMySitesTabToBlogDetailsForBlog:post.blog];

    BlogDetailsViewController *blogDetailVC = (BlogDetailsViewController *)self.blogListNavigationController.topViewController;
    if ([blogDetailVC isKindOfClass:[BlogDetailsViewController class]]) {
        [blogDetailVC showDetailViewForSubsection:BlogDetailsSubsectionPages];
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

- (void)switchMySitesTabToMediaForBlog:(Blog *)blog
{
    if (self.selectedIndex == WPTabMySites) {
        UIViewController *topViewController = (BlogDetailsViewController *)self.blogListNavigationController.topViewController;
        if ([topViewController isKindOfClass:[MediaLibraryViewController class]]) {
            MediaLibraryViewController *mediaVC = (MediaLibraryViewController *)topViewController;
            if (mediaVC.blog == blog) {
                // If media is already selected for the specified blog, do nothing.
                return;
            }
        }
    }
    
    [self switchMySitesTabToBlogDetailsForBlog:blog];

    BlogDetailsViewController *blogDetailVC = (BlogDetailsViewController *)self.blogListNavigationController.topViewController;
    if ([blogDetailVC isKindOfClass:[BlogDetailsViewController class]]) {
        [blogDetailVC showDetailViewForSubsection:BlogDetailsSubsectionMedia];
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

- (void)switchMeTabToAppSettings
{
    [self showMeTab];

    [self.meNavigationController popToRootViewControllerAnimated:NO];

    // If we don't dispatch_async here, the top inset of the app
    // settings VC isn't correct when pushed...
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.meViewController navigateToAppSettings];
    });
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
    UITabBarItem *notificationsTabBarItem = self.notificationsNavigationController.tabBarItem;
    if (count == 0) {
        notificationsTabBarItem.image = self.notificationsTabBarImage;
        notificationsTabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");
    } else {
        notificationsTabBarItem.image = self.notificationsTabBarImageUnread;
        notificationsTabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications Unread", @"Notifications tab bar item accessibility label, unread notifications state");
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

#pragma mark - Handling Layout

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateNotificationBadgeVisibility];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    [self updateWriteButtonAppearance];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
}

@end
