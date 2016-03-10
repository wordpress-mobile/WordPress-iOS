#import "WPTabBarController.h"
#import <WordPressShared/UIImage+Util.h>

#import "WordPressAppDelegate.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "BlogService.h"
#import "Blog.h"
#import "Post.h"

#import "BlogListViewController.h"
#import "BlogDetailsViewController.h"
#import "NotificationsViewController.h"
#import "PostListViewController.h"
#import "ReaderViewController.h"
#import "StatsViewController.h"
#import "WPPostViewController.h"
#import "WPLegacyEditPageViewController.h"
#import "WPScrollableViewController.h"
#import "HelpshiftUtils.h"
#import <WordPressShared/WPDeviceIdentification.h>
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"

static NSString * const WPTabBarRestorationID = @"WPTabBarID";
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

static NSInteger const WPTabBarIconOffset = 5;

@interface WPTabBarController () <UITabBarControllerDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) BlogListViewController *blogListViewController;
@property (nonatomic, strong) ReaderViewController *readerViewController;
@property (nonatomic, strong) NotificationsViewController *notificationsViewController;
@property (nonatomic, strong) MeViewController *meViewController;
@property (nonatomic, strong) UIViewController *newPostViewController;

@property (nonatomic, strong) UINavigationController *blogListNavigationController;
@property (nonatomic, strong) UINavigationController *readerNavigationController;
@property (nonatomic, strong) UINavigationController *notificationsNavigationController;
@property (nonatomic, strong) UINavigationController *meNavigationController;

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

        [self setViewControllers:@[self.blogListNavigationController,
                                   self.readerNavigationController,
                                   self.newPostViewController,
                                   self.meNavigationController,
                                   self.notificationsNavigationController]];

        [self setSelectedViewController:self.blogListNavigationController];

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
    if (selectedIndex == WPTabReader) {
        // Bumping the stat in this method works for cases where the selected tab is
        // set in response to other feature behavior (e.g. a notifications), and
        // when set via state restoration.
        [WPAnalytics track:WPAnalyticsStatReaderAccessed];
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
    _blogListNavigationController.tabBarItem.imageInsets = UIEdgeInsetsMake(WPTabBarIconOffset, 0, -1 * WPTabBarIconOffset, 0);
    _blogListNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"My Sites", @"The accessibility value of the my sites tab.");

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
    _readerNavigationController.tabBarItem.imageInsets = UIEdgeInsetsMake(WPTabBarIconOffset, -1 * WPTabBarIconOffset, -1 * WPTabBarIconOffset, WPTabBarIconOffset);
    _readerNavigationController.restorationIdentifier = WPReaderNavigationRestorationID;
    _readerNavigationController.tabBarItem.accessibilityIdentifier = @"Reader";
    _readerNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Reader", @"The accessibility value of the reader tab.");

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
    _newPostViewController.tabBarItem.imageInsets = UIEdgeInsetsMake(WPTabBarIconOffset, 0, -1 * WPTabBarIconOffset, 0);
    _newPostViewController.tabBarItem.accessibilityLabel = NSLocalizedString(@"New Post", @"The accessibility value of the post tab.");

    return _newPostViewController;
}

- (UINavigationController *)meNavigationController
{
    if (_meNavigationController) {
        return _meNavigationController;
    }

    self.meViewController = [MeViewController new];
    _meNavigationController = [[UINavigationController alloc] initWithRootViewController:self.meViewController];
    UIImage *meTabBarImage = [UIImage imageNamed:@"icon-tab-me"];
    _meNavigationController.tabBarItem.image = [meTabBarImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    _meNavigationController.tabBarItem.selectedImage = meTabBarImage;
    _meNavigationController.tabBarItem.imageInsets = UIEdgeInsetsMake(WPTabBarIconOffset, WPTabBarIconOffset, -1 * WPTabBarIconOffset, -1 * WPTabBarIconOffset);
    _meNavigationController.restorationIdentifier = WPMeNavigationRestorationID;
    _meNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Me", @"The accessibility value of the me tab.");

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
    _notificationsNavigationController.tabBarItem.imageInsets = UIEdgeInsetsMake(WPTabBarIconOffset, 0, -1 * WPTabBarIconOffset, 0);
    _notificationsNavigationController.restorationIdentifier = WPNotificationsNavigationRestorationID;
    _notificationsNavigationController.tabBarItem.accessibilityLabel = NSLocalizedString(@"Notifications", @"Notifications tab bar item accessibility label");

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
    BOOL animated = YES;
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }

    UINavigationController *navController;
    if ([WPPostViewController isNewEditorEnabled]) {
        WPPostViewController *editPostViewController;
        if (!options) {
            editPostViewController = [[WPPostViewController alloc] initWithDraftForLastUsedBlog];
            [WPAppAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{ @"tap_source": @"tab_bar"} withBlog:[editPostViewController post].blog];
        } else {
            if (options[WPPostViewControllerOptionOpenMediaPicker]) {
                editPostViewController = [[WPPostViewController alloc] initWithDraftForLastUsedBlogAndPhotoPost];
            } else {
                editPostViewController = [[WPPostViewController alloc] initWithTitle:[options stringForKey:WPNewPostURLParamTitleKey]
                                                                      andContent:[options stringForKey:WPNewPostURLParamContentKey]
                                                                         andTags:[options stringForKey:WPNewPostURLParamTagsKey]
                                                                        andImage:[options stringForKey:WPNewPostURLParamImageKey]];
            }
            
            if (options[WPPostViewControllerOptionNotAnimated]) {
                animated = NO;
            }
        }
        navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
        navController.restorationIdentifier = WPEditorNavigationRestorationID;
        navController.restorationClass = [WPPostViewController class];
    } else {
        WPLegacyEditPostViewController *editPostLegacyViewController;
        if (!options) {
            editPostLegacyViewController = [[WPLegacyEditPostViewController alloc] initWithDraftForLastUsedBlog];
            NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
            BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
            Blog *blog = [blogService lastUsedOrFirstBlog];
            [WPAppAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{ @"tap_source": @"tab_bar"} withBlog:blog];
        } else {
            editPostLegacyViewController = [[WPLegacyEditPostViewController alloc] initWithTitle:[options stringForKey:WPNewPostURLParamTitleKey]
                                                                                      andContent:[options stringForKey:WPNewPostURLParamContentKey]
                                                                                         andTags:[options stringForKey:WPNewPostURLParamTagsKey]
                                                                                        andImage:[options stringForKey:WPNewPostURLParamImageKey]];
        }
        navController = [[UINavigationController alloc] initWithRootViewController:editPostLegacyViewController];
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        navController.restorationClass = [WPLegacyEditPostViewController class];
    }

    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    navController.navigationBar.translucent = NO;
    [navController setToolbarHidden:NO]; // Make the toolbar visible here to avoid a weird left/right transition when the VC appears.
    [self presentViewController:navController animated:animated completion:nil];
}

- (void)switchTabToPostsListForPost:(AbstractPost *)post
{
    // Make sure the desired tab is selected.
    [self showTabForIndex:WPTabMySites];

    // Check which VC is showing.
    UIViewController *topVC = self.blogListNavigationController.topViewController;
    if ([topVC isKindOfClass:[PostListViewController class]]) {
        Blog *blog = ((PostListViewController *)topVC).blog;
        if ([post.blog.objectID isEqual:blog.objectID]) {
            // The desired post view controller is already the top viewController for the tab.
            // Nothing to see here.  Move along.
            return;
        }
    }

    // Build and set the navigation heirarchy for the Me tab.
    BlogDetailsViewController *blogDetailsViewController = [[BlogDetailsViewController alloc] init];
    blogDetailsViewController.blog = post.blog;

    PostListViewController *postsViewController = [PostListViewController controllerWithBlog:post.blog];

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

- (void)switchMySitesTabToCustomizeViewForBlog:(Blog *)blog
{
    [self showTabForIndex:WPTabMySites];
    
    BlogDetailsViewController *blogDetailsViewController = [BlogDetailsViewController new];
    blogDetailsViewController.blog = blog;
    
    ThemeBrowserViewController *viewController = [ThemeBrowserViewController browserWithBlog:blog];
    
    [self.blogListNavigationController setViewControllers:@[self.blogListViewController, blogDetailsViewController, viewController]];
    [viewController presentCustomizeForTheme:[viewController currentTheme]];
}

- (void)switchMySitesTabToThemesViewForBlog:(Blog *)blog
{
    [self showTabForIndex:WPTabMySites];
    
    BlogDetailsViewController *blogDetailsViewController = [BlogDetailsViewController new];
    blogDetailsViewController.blog = blog;
    
    ThemeBrowserViewController *viewController = [ThemeBrowserViewController browserWithBlog:blog];
    
    [self.blogListNavigationController setViewControllers:@[self.blogListViewController, blogDetailsViewController, viewController]];
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
    } else if ([tabBarController.viewControllers indexOfObject:viewController] == WPTabReader && tabBarController.selectedIndex != WPTabReader) {
        // Bump the accessed stat when switching to the reader tab, but not if the tab is tapped when already selected.
        [WPAnalytics track:WPAnalyticsStatReaderAccessed];
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
    CGRect notificationsButtonFrame = [self lastTabBarButtonFrame];
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
    // *If* this ever breaks, worst case scenario, we'll notice the assertion below (and of course, we'll fix it!).
    //
    CGRect lastButtonRect = CGRectZero;
    
    for (UIView *subview in self.tabBar.subviews) {
        if ([WPTabBarButtonClassname isEqualToString:NSStringFromClass([subview class])]) {
            if (CGRectGetMinX(subview.frame) > CGRectGetMinX(lastButtonRect)) {
                lastButtonRect = subview.frame;
            }
        }
    }
    
    NSAssert(!CGRectEqualToRect(lastButtonRect, CGRectZero), @"Couldn't determine the last TabBarButton Frame");
    return lastButtonRect;
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

@end
