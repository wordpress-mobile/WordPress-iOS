#import "WPTabBarController.h"
#import <WordPress-iOS-Shared/UIImage+Util.h>

#import "WordPressAppDelegate.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "BlogService.h"
#import "Blog.h"
#import "Post.h"

#import "BlogListViewController.h"
#import "BlogDetailsViewController.h"
#import "MeViewController.h"
#import "NotificationsViewController.h"
#import "PostsViewController.h"
#import "ReaderViewController.h"
#import "StatsViewController.h"
#import "WPPostViewController.h"
#import "WPLegacyEditPageViewController.h"
#import "WPScrollableViewController.h"
#import "HelpshiftUtils.h"

NSString * const WPTabBarRestorationID = @"WPTabBarID";
NSString * const WPBlogListNavigationRestorationID = @"WPBlogListNavigationID";
NSString * const WPReaderNavigationRestorationID= @"WPReaderNavigationID";
NSString * const WPNotificationsNavigationRestorationID  = @"WPNotificationsNavigationID";

NSString * const kWPNewPostURLParamTitleKey = @"title";
NSString * const kWPNewPostURLParamContentKey = @"content";
NSString * const kWPNewPostURLParamTagsKey = @"tags";
NSString * const kWPNewPostURLParamImageKey = @"image";

@interface WPTabBarController () <UITabBarControllerDelegate>

@property (nonatomic, strong) BlogListViewController *blogListViewController;
@property (nonatomic, strong) ReaderViewController *readerViewController;
@property (nonatomic, strong) NotificationsViewController *notificationsViewController;
@property (nonatomic, strong) MeViewController *meViewController;
@property (nonatomic, strong) UIViewController *newPostViewController;

@property (nonatomic, strong) UINavigationController *blogListNavigationController;
@property (nonatomic, strong) UINavigationController *readerNavigationController;
@property (nonatomic, strong) UINavigationController *notificationsNavigationController;
@property (nonatomic, strong) UINavigationController *meNavigationController;

@end

@implementation WPTabBarController

+ (instancetype)sharedInstance
{
    static WPTabBarController *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setDelegate:self];

        [self setRestorationIdentifier:WPTabBarRestorationID];
        [[self tabBar] setTranslucent:NO];
        [[self tabBar] setAccessibilityIdentifier:NSLocalizedString(@"Main Navigation", @"")];
        // Create a background
        // (not strictly needed when white, but left here for possible customization)
        [[self tabBar] setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]]];

        [self setViewControllers:@[self.blogListNavigationController,
                                   self.readerNavigationController,
                                   self.newPostViewController,
                                   self.meNavigationController,
                                   self.notificationsNavigationController]];

        [self setSelectedViewController:self.blogListNavigationController];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(helpshiftUnreadCountUpdated:)
                                                     name:HelpshiftUnreadCountUpdatedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(defaultAccountDidChange:)
                                                     name:WPAccountDefaultWordPressComAccountChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    self.blogListViewController.title = NSLocalizedString(@"My Sites", @"");
    [_blogListNavigationController.tabBarItem setTitlePositionAdjustment:self.tabBarTitleOffset];
    _blogListNavigationController.tabBarItem.accessibilityIdentifier = NSLocalizedString(@"My Sites", @"");

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    Blog *blogToOpen = [blogService lastUsedOrFirstBlog];
    if (blogToOpen) {
        BlogDetailsViewController *blogDetailsViewController = [[BlogDetailsViewController alloc] init];
        blogDetailsViewController.blog = blogToOpen;
        [_blogListNavigationController pushViewController:blogDetailsViewController animated:NO];
    }

    return _blogListNavigationController;
}

- (UINavigationController *)readerNavigationController
{
    if (_readerNavigationController) {
        return _readerNavigationController;
    }

    self.readerViewController = [[ReaderViewController alloc] init];
    _readerNavigationController = [[UINavigationController alloc] initWithRootViewController:self.readerViewController];
    _readerNavigationController.navigationBar.translucent = NO;
    UIImage *readerTabBarImage = [UIImage imageNamed:@"icon-tab-reader"];
    _readerNavigationController.tabBarItem.image = [readerTabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    _readerNavigationController.tabBarItem.selectedImage = readerTabBarImage;
    _readerNavigationController.restorationIdentifier = WPReaderNavigationRestorationID;
    [_readerNavigationController.tabBarItem setTitlePositionAdjustment:self.tabBarTitleOffset];
    _readerNavigationController.tabBarItem.title = NSLocalizedString(@"Reader", @"Description of the Reader tab");

    return _readerNavigationController;
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
    _newPostViewController.tabBarItem.imageInsets = UIEdgeInsetsMake(5.0, 0, -5.0, 0);

    /*
     If title is used, the title will be visible. See #1158
     If accessibilityLabel/Value are used, the "New Post" text is not read by VoiceOver

     The only apparent solution is to have an actual title, and then move it out of view
     non-VoiceOver users.
     */
    _newPostViewController.title = NSLocalizedString(@"New Post", @"The accessibility value of the post tab.");
    _newPostViewController.tabBarItem.titlePositionAdjustment = UIOffsetMake(0, 20.0);

    return _newPostViewController;
}

- (UINavigationController *)meNavigationController
{
    if (_meNavigationController) {
        return _meNavigationController;
    }

    self.meViewController = [MeViewController new];
    UIImage *meTabBarImage = [UIImage imageNamed:@"icon-tab-me"];
    self.meViewController.tabBarItem.image = [meTabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.meViewController.tabBarItem.selectedImage = meTabBarImage;
    self.meViewController.tabBarItem.titlePositionAdjustment = self.tabBarTitleOffset;
    self.meViewController.title = NSLocalizedString(@"Me", @"Me page title");
    _meNavigationController = [[UINavigationController alloc] initWithRootViewController:self.meViewController];

    return _meNavigationController;
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
    self.notificationsViewController.title = NSLocalizedString(@"Notifications", @"");
    [_notificationsNavigationController.tabBarItem setTitlePositionAdjustment:self.tabBarTitleOffset];

    return _notificationsNavigationController;
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
    [self showPostTabWithOptions:nil];
}

- (void)showNotificationsTab
{
    [self showTabForIndex:WPTabNotifications];
}

- (void)showPostTabWithOptions:(NSDictionary *)options
{
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }

    UINavigationController *navController;
    if ([WPPostViewController isNewEditorEnabled]) {
        WPPostViewController *editPostViewController;
        if (!options) {
            [WPAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{ @"tap_source": @"tab_bar" }];
            editPostViewController = [[WPPostViewController alloc] initWithDraftForLastUsedBlog];
        } else {
            editPostViewController = [[WPPostViewController alloc] initWithTitle:[options stringForKey:kWPNewPostURLParamTitleKey]
                                                                      andContent:[options stringForKey:kWPNewPostURLParamContentKey]
                                                                         andTags:[options stringForKey:kWPNewPostURLParamTagsKey]
                                                                        andImage:[options stringForKey:kWPNewPostURLParamImageKey]];
        }
        navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
        navController.restorationIdentifier = WPEditorNavigationRestorationID;
        navController.restorationClass = [WPPostViewController class];
    } else {
        WPLegacyEditPostViewController *editPostLegacyViewController;
        if (!options) {
            [WPAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{ @"tap_source": @"tab_bar" }];
            editPostLegacyViewController = [[WPLegacyEditPostViewController alloc] initWithDraftForLastUsedBlog];
        } else {
            editPostLegacyViewController = [[WPLegacyEditPostViewController alloc] initWithTitle:[options stringForKey:kWPNewPostURLParamTitleKey]
                                                                                      andContent:[options stringForKey:kWPNewPostURLParamContentKey]
                                                                                         andTags:[options stringForKey:kWPNewPostURLParamTagsKey]
                                                                                        andImage:[options stringForKey:kWPNewPostURLParamImageKey]];
        }
        navController = [[UINavigationController alloc] initWithRootViewController:editPostLegacyViewController];
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        navController.restorationClass = [WPLegacyEditPostViewController class];
    }

    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    navController.navigationBar.translucent = NO;
    [navController setToolbarHidden:NO]; // Make the toolbar visible here to avoid a weird left/right transition when the VC appears.
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)switchTabToPostsListForPost:(AbstractPost *)post
{
    // Make sure the desired tab is selected.
    [self showTabForIndex:WPTabMySites];

    // Check which VC is showing.
    UIViewController *topVC = self.blogListNavigationController.topViewController;
    if ([topVC isKindOfClass:[PostsViewController class]]) {
        Blog *blog = ((PostsViewController *)topVC).blog;
        if ([post.blog.objectID isEqual:blog.objectID]) {
            // The desired post view controller is already the top viewController for the tab.
            // Nothing to see here.  Move along.
            return;
        }
    }

    // Build and set the navigation heirarchy for the Me tab.
    BlogDetailsViewController *blogDetailsViewController = [[BlogDetailsViewController alloc] init];
    blogDetailsViewController.blog = post.blog;

    PostsViewController *postsViewController = [[PostsViewController alloc] init];
    [postsViewController setBlog:post.blog];

    [self.blogListNavigationController setViewControllers:@[self.blogListViewController, blogDetailsViewController, postsViewController]];
}

- (void)switchMySitesTabToStatsViewForBlog:(Blog *)blog
{
    // Make sure the desired tab is selected.
    [self showTabForIndex:WPTabMySites];

    // Build and set the navigation heirarchy for the Me tab.
    BlogDetailsViewController *blogDetailsViewController = [BlogDetailsViewController new];
    blogDetailsViewController.blog = blog;

    StatsViewController *statsViewController = [StatsViewController new];
    statsViewController.blog = blog;

    [self.blogListNavigationController setViewControllers:@[self.blogListViewController, blogDetailsViewController, statsViewController]];
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

#pragma mark - UITabBarControllerDelegate methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if ([tabBarController.viewControllers indexOfObject:viewController] == WPTabNewPost) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

        // Ignore taps on the post tab and instead show the modal.
        if ([blogService blogCountVisibleForAllAccounts] == 0) {
            [[WordPressAppDelegate sharedInstance] showWelcomeScreenAnimated:YES thenEditor:YES];
        } else {
            [self showPostTab];
        }
        return NO;
    } else if ([tabBarController.viewControllers indexOfObject:viewController] == WPTabMySites) {
        // If the user has one blog then we don't want to present them with the main "me"
        // screen where they can see all their blogs. In the case of only one blog just show
        // the main blog details screen

        // Don't kick of this auto selecting behavior if the user taps the the active tab as it
        // would break from standard iOS UX
        if (tabBarController.selectedIndex != WPTabNewPost) {
            UINavigationController *navController = (UINavigationController *)viewController;
            BlogListViewController *blogListViewController = (BlogListViewController *)navController.viewControllers[0];
            if ([blogListViewController shouldBypassBlogListViewControllerWhenSelectedFromTabBar]) {
                if ([navController.visibleViewController isKindOfClass:[blogListViewController class]]) {
                    [blogListViewController bypassBlogListViewController];
                }
            }
        }
    }

    // If the current view controller is selected already and it's at its root then scroll to the top
    if (tabBarController.selectedViewController == viewController) {
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navController = (UINavigationController *)viewController;
            if (navController.topViewController == navController.viewControllers.firstObject) {
                UIViewController *topViewController = navController.topViewController;
                if ([topViewController.view isKindOfClass:[UITableView class]]) {
                    UITableView *tableView = (UITableView *)topViewController.view;
                    CGPoint topOffset = CGPointMake(0.0f, -tableView.contentInset.top);
                    [tableView setContentOffset:topOffset animated:YES];
                } else if ([[topViewController class] conformsToProtocol:@protocol(WPScrollableViewController)]) {
                    [((id<WPScrollableViewController>)topViewController) scrollViewToTop];
                }
            }
        }
    }

    return YES;
}

- (void)showNotificationsTabForNoteWithID:(NSString *)notificationID
{
    [self showTabForIndex:WPTabNotifications];
    [self.notificationsViewController showDetailsForNoteWithID:notificationID];
}

- (BOOL)isNavigatingMySitesTab
{
    return (self.selectedIndex == WPTabMySites && [self.blogListViewController.navigationController.viewControllers count] > 1);
}

#pragma mark - Helpers

- (UIOffset)tabBarTitleOffset {
    return IS_IPHONE ? UIOffsetMake(0, -2) : UIOffsetZero;
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
    [self.blogListNavigationController popToRootViewControllerAnimated:NO];
    [self.readerNavigationController popToRootViewControllerAnimated:NO];
    [self.meNavigationController popToRootViewControllerAnimated:NO];
    [self.notificationsNavigationController popToRootViewControllerAnimated:NO];
}

@end
