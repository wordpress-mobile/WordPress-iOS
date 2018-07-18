#import "BlogDetailsViewController.h"

#import "AccountService.h"
#import "BlogService.h"
#import "BlogDetailHeaderView.h"
#import "CommentsViewController.h"
#import "ContextManager.h"
#import "ReachabilityUtils.h"
#import "SiteSettingsViewController.h"
#import "SharingViewController.h"
#import "StatsViewController.h"
#import "WPAccount.h"
#import "WPAppAnalytics.h"
#import "WPGUIConstants.h"
#import "WordPress-Swift.h"
#import "MenusViewController.h"
#import <Reachability/Reachability.h>
#import <WordPressShared/WPTableViewCell.h>

@import WordPressComStatsiOS;
@import Gridicons;

static NSString *const BlogDetailsCellIdentifier = @"BlogDetailsCell";
static NSString *const BlogDetailsPlanCellIdentifier = @"BlogDetailsPlanCell";
static NSString *const BlogDetailsSettingsCellIdentifier = @"BlogDetailsSettingsCell";
static NSString *const BlogDetailsRemoveSiteCellIdentifier = @"BlogDetailsRemoveSiteCell";

NSString * const WPBlogDetailsRestorationID = @"WPBlogDetailsID";
NSString * const WPBlogDetailsBlogKey = @"WPBlogDetailsBlogKey";
NSString * const WPBlogDetailsSelectedIndexPathKey = @"WPBlogDetailsSelectedIndexPathKey";

NSInteger const BlogDetailHeaderViewVerticalMargin = 18;
CGFloat const BLogDetailGridiconAccessorySize = 17.0;
NSTimeInterval const PreloadingCacheTimeout = 60.0 * 5; // 5 minutes
NSString * const HideWPAdminDate = @"2015-09-07T00:00:00Z";

// NOTE: Currently "stats" acts as the calypso dashboard with a redirect to
// stats/insights. Per @mtias, if the dashboard should change at some point the
// redirect will be updated to point to new content, eventhough the path is still
// "stats/".
// aerych, 2016-06-14
NSString * const WPCalypsoDashboardPath = @"https://wordpress.com/stats/";

#pragma mark - Helper Classes for Blog Details view model.

@interface BlogDetailsRow : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *accessibilityIdentifier;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImageView *accessoryView;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic) BOOL showsSelectionState;
@property (nonatomic) BOOL forDestructiveAction;
@property (nonatomic, copy) void (^callback)(void);

@end

@implementation BlogDetailsRow

- (instancetype)initWithTitle:(NSString * __nonnull)title
                        image:(UIImage * __nonnull)image
                     callback:(void(^)(void))callback
{
    return [self initWithTitle:title
                    identifier:BlogDetailsCellIdentifier
                         image:image
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
                   identifier:(NSString * __nonnull)identifier
                        image:(UIImage * __nonnull)image
                     callback:(void(^)(void))callback
{
    return [self initWithTitle:title
                    identifier:identifier
       accessibilityIdentifier:nil
                         image:image
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
      accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
                        image:(UIImage * __nonnull)image
                     callback:(void(^)(void))callback
{
    return [self initWithTitle:title
                    identifier:BlogDetailsCellIdentifier
       accessibilityIdentifier:accessibilityIdentifier
                         image:image
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
                   identifier:(NSString * __nonnull)identifier
      accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
                        image:(UIImage * __nonnull)image
                     callback:(void(^)(void))callback
{
    self = [super init];
    if (self) {
        _title = title;
        _image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _callback = callback;
        _identifier = identifier;
        _accessibilityIdentifier = accessibilityIdentifier;
        _showsSelectionState = YES;
    }
    return self;
}

@end

@interface BlogDetailsSection : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSArray *rows;

@end

@implementation BlogDetailsSection
- (instancetype)initWithTitle:(NSString *)title andRows:(NSArray *)rows
{
    self = [super init];
    if (self) {
        _title = title;
        _rows = rows;
    }
    return self;
}
@end

#pragma mark -

@interface BlogDetailsViewController () <UIActionSheetDelegate, UIAlertViewDelegate, WPSplitViewControllerDetailProvider, BlogDetailHeaderViewDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) BlogDetailHeaderView *headerView;
@property (nonatomic, strong) NSArray *headerViewHorizontalConstraints;
@property (nonatomic, strong) NSArray *tableSections;
@property (nonatomic, strong) WPStatsService *statsService;
@property (nonatomic, strong) BlogService *blogService;
@property (nonatomic, strong) SiteIconPickerPresenter *siteIconPickerPresenter;
@property (nonatomic, strong) ImageCropViewController *imageCropViewController;

/// Used to restore the tableview selection during state restoration, and
/// also when switching between a collapsed and expanded split view controller presentation
@property (nonatomic, strong) NSIndexPath *restorableSelectedIndexPath;

@end

@implementation BlogDetailsViewController

#pragma mark - State Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSString *blogID = [coder decodeObjectForKey:WPBlogDetailsBlogKey];
    if (!blogID) {
        return nil;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:blogID]];
    if (!objectID) {
        return nil;
    }

    NSError *error = nil;
    Blog *restoredBlog = (Blog *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredBlog) {
        return nil;
    }

    // If there's already a blog details view controller for this blog in the primary
    // navigation stack, we'll return that instead of creating a new one.
    UISplitViewController *splitViewController = [[WPTabBarController sharedInstance] blogListSplitViewController];
    UINavigationController *navigationController = splitViewController.viewControllers.firstObject;
    if (navigationController && [navigationController isKindOfClass:[UINavigationController class]]) {
        BlogDetailsViewController *topViewController = (BlogDetailsViewController *)navigationController.topViewController;
        if ([topViewController isKindOfClass:[BlogDetailsViewController class]] && topViewController.blog == restoredBlog) {
            return topViewController;
        }
    }

    BlogDetailsViewController *viewController = [[self alloc] initWithStyle:UITableViewStyleGrouped];
    viewController.blog = restoredBlog;

    return viewController;
}


- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[[self.blog.objectID URIRepresentation] absoluteString] forKey:WPBlogDetailsBlogKey];

    WPSplitViewController *splitViewController = (WPSplitViewController *)self.splitViewController;

    UIViewController *detailViewController = [splitViewController rootDetailViewController];
    if (detailViewController && [detailViewController conformsToProtocol:@protocol(UIViewControllerRestoration)]) {
        // If the current detail view controller supports state restoration, store the current selection
        [coder encodeObject:self.restorableSelectedIndexPath forKey:WPBlogDetailsSelectedIndexPathKey];
    }

    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSIndexPath *indexPath = [coder decodeObjectForKey:WPBlogDetailsSelectedIndexPathKey];
    if (indexPath) {
        self.restorableSelectedIndexPath = indexPath;
    }

    [super decodeRestorableStateWithCoder:coder];
}

#pragma mark = Lifecycle Methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.restorationIdentifier = WPBlogDetailsRestorationID;
        self.restorationClass = [self class];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.accessibilityIdentifier = @"Blog Details Table";

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [WPStyleGuide configureAutomaticHeightRowsFor:self.tableView];
    
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:BlogDetailsCellIdentifier];
    [self.tableView registerClass:[WPTableViewCellValue1 class] forCellReuseIdentifier:BlogDetailsPlanCellIdentifier];
    [self.tableView registerClass:[WPTableViewCellValue1 class] forCellReuseIdentifier:BlogDetailsSettingsCellIdentifier];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:BlogDetailsRemoveSiteCellIdentifier];

    self.clearsSelectionOnViewWillAppear = NO;

    __weak __typeof(self) weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    self.blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [self.blogService syncBlogAndAllMetadata:_blog
                           completionHandler:^{
                               [weakSelf configureTableViewData];
                               [weakSelf reloadTableViewPreservingSelection];
                           }];
    if (self.blog.account && !self.blog.account.userID) {
        // User's who upgrade may not have a userID recorded.
        AccountService *acctService = [[AccountService alloc] initWithManagedObjectContext:context];
        [acctService updateUserDetailsForAccount:self.blog.account success:nil failure:nil];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDataModelChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:context];

    [self configureBlogDetailHeader];
    [self.headerView setBlog:_blog];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.splitViewControllerIsHorizontallyCompact) {
        [self animateDeselectionInteractively];
        self.restorableSelectedIndexPath = nil;
    }

    [self.headerView setBlog:self.blog];

    // Configure and reload table data when appearing to ensure pending comment count is updated
    [self configureTableViewData];

    [self reloadTableViewPreservingSelection];
    [self preloadBlogData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self createUserActivity];
    [self showNotificationPrimerAlert];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    // Required to update disclosure indicators depending on split view status
    [self reloadTableViewPreservingSelection];
}

- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section
{
    NSIndexPath *indexPath = [self indexPathForSubsection:section];

    switch (section) {
        case BlogDetailsSubsectionStats:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            [self showStats];
            break;
        case BlogDetailsSubsectionPosts:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            [self showPostList];
            break;
        case BlogDetailsSubsectionThemes:
        case BlogDetailsSubsectionCustomize:
            if ([self.blog supports:BlogFeatureThemeBrowsing] || [self.blog supports:BlogFeatureMenus]) {
                self.restorableSelectedIndexPath = indexPath;
                [self.tableView selectRowAtIndexPath:indexPath
                                            animated:NO
                                      scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
                [self showThemes];
            }
            break;
        case BlogDetailsSubsectionMedia:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            [self showMediaLibrary];
            break;
        case BlogDetailsSubsectionPages:
            self.restorableSelectedIndexPath = indexPath;
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:[self optimumScrollPositionForIndexPath:indexPath]];
            [self showPageList];
            break;
    }
}

- (NSIndexPath *)indexPathForSubsection:(BlogDetailsSubsection)section
{
    switch (section) {
        case BlogDetailsSubsectionStats:
            return [NSIndexPath indexPathForRow:0 inSection:0];
        case BlogDetailsSubsectionPosts:
            return [NSIndexPath indexPathForRow:0 inSection:1];
        case BlogDetailsSubsectionThemes:
        case BlogDetailsSubsectionCustomize:
            return [NSIndexPath indexPathForRow:0 inSection:2];
        case BlogDetailsSubsectionMedia:
            return [NSIndexPath indexPathForRow:2 inSection:1];
        case BlogDetailsSubsectionPages:
            return [NSIndexPath indexPathForRow:0 inSection:0];
    }
}

#pragma mark - Properties

- (NSIndexPath *)restorableSelectedIndexPath
{
    if (!_restorableSelectedIndexPath) {
        _restorableSelectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }

    return _restorableSelectedIndexPath;
}

- (SiteIconPickerPresenter *)siteIconPickerPresenter
{
    if (!_siteIconPickerPresenter) {
        _siteIconPickerPresenter = [[SiteIconPickerPresenter alloc]initWithBlog:self.blog];
    }
    return _siteIconPickerPresenter;
}

#pragma mark - Data Model setup

- (void)reloadTableViewPreservingSelection
{
    // First, we'll grab the appropriate index path so we can reselect it
    // after reloading the table
    NSIndexPath *selectedIndexPath = self.restorableSelectedIndexPath;

    // Configure and reload table data when appearing to ensure pending comment count is updated
    [self.tableView reloadData];

    if (![self splitViewControllerIsHorizontallyCompact]) {
        // And finally we'll reselect the selected row, if there is one

        [self.tableView selectRowAtIndexPath:selectedIndexPath
                                    animated:NO
                              scrollPosition:[self optimumScrollPositionForIndexPath:selectedIndexPath]];
    }
}

- (UITableViewScrollPosition)optimumScrollPositionForIndexPath:(NSIndexPath *)indexPath
{
    // Try and avoid scrolling if not necessary
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
    BOOL cellIsNotFullyVisible = !CGRectContainsRect(self.tableView.bounds, cellRect);
    return (cellIsNotFullyVisible) ? UITableViewScrollPositionMiddle : UITableViewScrollPositionNone;
}

- (void)configureTableViewData
{
    NSMutableArray *marr = [NSMutableArray array];
    [marr addObject:[self generalSectionViewModel]];
    [marr addObject:[self publishTypeSectionViewModel]];
    if ([self.blog supports:BlogFeatureThemeBrowsing] || [self.blog supports:BlogFeatureMenus]) {
        [marr addObject:[self personalizeSectionViewModel]];
    }
    [marr addObject:[self configurationSectionViewModel]];
    [marr addObject:[self externalSectionViewModel]];
    if ([self.blog supports:BlogFeatureRemovable]) {
        [marr addObject:[self removeSiteSectionViewModel]];
    }

    // Assign non mutable copy.
    self.tableSections = [NSArray arrayWithArray:marr];
}

- (BlogDetailsSection *)generalSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];

    if ([Feature enabled:FeatureFlagWhatsNext]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Quick Start", @"Name of the Quick Start feature that guides users through a few tasks to setup their new website.")
                                                        image:[Gridicon iconOfType:GridiconTypeStatsAlt]
                                                     callback:^{
                                                         [weakSelf startTour];
                                                     }]];
    }

    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Stats", @"Noun. Abbv. of Statistics. Links to a blog's Stats screen.")
                                                    image:[Gridicon iconOfType:GridiconTypeStatsAlt]
                                                 callback:^{
                                                     [weakSelf showStats];
                                                 }]];

    if ([self.blog supports:BlogFeatureActivity]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Activity", @"Noun. Links to a blog's Activity screen.")
                                                        image:[Gridicon iconOfType:GridiconTypeHistory]
                                                     callback:^{
                                                         [weakSelf showActivity];
                                                     }]];
    }

    if ([self.blog supports:BlogFeaturePlans]) {
        BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Plans", @"Action title. Noun. Links to a blog's Plans screen.")
                                                         identifier:BlogDetailsPlanCellIdentifier
                                                              image:[Gridicon iconOfType:GridiconTypePlans]
                                                           callback:^{
                                                               [weakSelf showPlans];
                                                           }];

        row.detail = self.blog.planTitle;

        [rows addObject:row];
    }

    return [[BlogDetailsSection alloc] initWithTitle:nil andRows:rows];
}

- (BlogDetailsSection *)publishTypeSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Site Pages", @"Noun. Title. Links to the blog's Pages screen.")
                                                    image:[Gridicon iconOfType:GridiconTypePages]
                                                 callback:^{
                                                     [weakSelf showPageList];
                                                 }]];

    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Blog Posts", @"Noun. Title. Links to the blog's Posts screen.")
                                  accessibilityIdentifier:@"Blog Post Row"
                                                    image:[[Gridicon iconOfType:GridiconTypePosts] imageFlippedForRightToLeftLayoutDirection]
                                                 callback:^{
                                                     [weakSelf showPostList];
                                                 }]];


    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Media", @"Noun. Title. Links to the blog's Media library.")
                                                    image:[Gridicon iconOfType:GridiconTypeImage]
                                                 callback:^{
                                                     [weakSelf showMediaLibrary];
                                                 }]];

    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Comments", @"Noun. Title. Links to the blog's Comments screen.")
                                                          image:[[Gridicon iconOfType:GridiconTypeComment] imageFlippedForRightToLeftLayoutDirection]
                                                       callback:^{
                                                           [weakSelf showComments];
                                                       }];
    NSUInteger numberOfPendingComments = [self.blog numberOfPendingComments];
    if (numberOfPendingComments > 0) {
        row.detail = [NSString stringWithFormat:@"%d", numberOfPendingComments];
    }
    [rows addObject:row];

    NSString *title = NSLocalizedString(@"Publish", @"Section title for the publish table section in the blog details screen");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows];
}

- (BlogDetailsSection *)personalizeSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    if ([self.blog supports:BlogFeatureThemeBrowsing]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Themes", @"Themes option in the blog details")
                                                        image:[Gridicon iconOfType:GridiconTypeThemes]
                                                     callback:^{
                                                         [weakSelf showThemes];
                                                     }]];
    }
    if ([self.blog supports:BlogFeatureMenus]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Menus", @"Menus option in the blog details")
                                                        image:[[Gridicon iconOfType:GridiconTypeMenus] imageFlippedForRightToLeftLayoutDirection]
                                                     callback:^{
                                                         [weakSelf showMenus];
                                                     }]];
    }
    NSString *title =NSLocalizedString(@"Personalize", @"Section title for the personalize table section in the blog details screen.");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows];
}

- (BlogDetailsSection *)configurationSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];

    if ([self.blog supports:BlogFeatureSharing]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Sharing", @"Noun. Title. Links to a blog's sharing options.")
                                                        image:[Gridicon iconOfType:GridiconTypeShare]
                                                     callback:^{
                                                         [weakSelf showSharing];
                                                     }]];
    }

    if ([self.blog supports:BlogFeaturePeople]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"People", @"Noun. Title. Links to the people management feature.")
                                                        image:[Gridicon iconOfType:GridiconTypeUser]
                                                     callback:^{
                                                         [weakSelf showPeople];
                                                     }]];
    }

    if ([self.blog supports:BlogFeaturePluginManagement]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Plugins", @"Noun. Title. Links to the plugin management feature.")
                                                        image:[Gridicon iconOfType:GridiconTypePlugins]
                                                     callback:^{
                                                         [weakSelf showPlugins];
                                                     }]];
    }

    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Settings", @"Noun. Title. Links to the blog's Settings screen.")
                                                     identifier:BlogDetailsSettingsCellIdentifier
                                                          image:[Gridicon iconOfType:GridiconTypeCog]
                                                       callback:^{
                                                           [weakSelf showSettings];
                                                       }];

    [rows addObject:row];

    NSString *title = NSLocalizedString(@"Configure", @"Section title for the configure table section in the blog details screen");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows];
}

- (BlogDetailsSection *)externalSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    BlogDetailsRow *viewSiteRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"View Site", @"Action title. Opens the user's site in an in-app browser")
                                                                  image:[Gridicon iconOfType:GridiconTypeHouse]
                                                               callback:^{
                                                                   [weakSelf showViewSite];
                                                               }];
    viewSiteRow.showsSelectionState = NO;
    [rows addObject:viewSiteRow];

    if ([self shouldDisplayLinkToWPAdmin]) {
        BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:[self adminRowTitle]
                                                              image:[Gridicon iconOfType:GridiconTypeMySites]
                                                           callback:^{
                                                               [weakSelf showViewAdmin];
                                                               [weakSelf.tableView deselectSelectedRowWithAnimation:YES];
                                                           }];
        UIImage *image = [[Gridicon iconOfType:GridiconTypeExternal withSize:CGSizeMake(BLogDetailGridiconAccessorySize, BLogDetailGridiconAccessorySize)] imageFlippedForRightToLeftLayoutDirection];
        UIImageView *accessoryView = [[UIImageView alloc] initWithImage:image];
        accessoryView.tintColor = [WPStyleGuide cellGridiconAccessoryColor]; // Match disclosure icon color.
        row.accessoryView = accessoryView;
        row.showsSelectionState = NO;
        [rows addObject:row];
    }

    NSString *title = NSLocalizedString(@"External", @"Section title for the external table section in the blog details screen");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows];
}

- (BlogDetailsSection *)removeSiteSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    BlogDetailsRow *removeSiteRow = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Remove Site", @"Button to remove a site from the app")
                                                               identifier:BlogDetailsRemoveSiteCellIdentifier
                                                                    image:nil
                                                                 callback:^{
                                                                     [weakSelf.tableView deselectSelectedRowWithAnimation:YES];
                                                                     [weakSelf showRemoveSiteAlert];
                                                                 }];
    removeSiteRow.showsSelectionState = NO;
    removeSiteRow.forDestructiveAction = YES;
    [rows addObject:removeSiteRow];

    return [[BlogDetailsSection alloc] initWithTitle:nil andRows:rows];

}

- (NSString *)adminRowTitle
{
    if (self.blog.isHostedAtWPcom) {
        return NSLocalizedString(@"Dashboard", @"Action title. Noun. Opens the user's WordPress.com dashboard in an external browser.");
    } else {
        return NSLocalizedString(@"WP Admin", @"Action title. Noun. Opens the user's WordPress Admin in an external browser.");
    }
}

// Non .com users and .com user whose accounts were created
// before LastWPAdminAccessDate should have access to WPAdmin
- (BOOL)shouldDisplayLinkToWPAdmin
{
    if (!self.blog.isHostedAtWPcom) {
        return YES;
    }
    NSDate *hideWPAdminDate = [NSDate dateWithISO8601String:HideWPAdminDate];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    return [defaultAccount.dateCreated compare:hideWPAdminDate] == NSOrderedAscending;
}

#pragma mark - Configuration

- (void)configureBlogDetailHeader
{
    // Wrapper view
    UIView *headerWrapper = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), BlogDetailHeaderViewBlavatarSize + BlogDetailHeaderViewVerticalMargin * 2)];
    headerWrapper.preservesSuperviewLayoutMargins = YES;
    self.tableView.tableHeaderView = headerWrapper;

    // Blog detail header view
    BlogDetailHeaderView *headerView = [[BlogDetailHeaderView alloc] init];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.delegate = self;
    [headerWrapper addSubview:headerView];

    UILayoutGuide *readableGuide = headerWrapper.readableContentGuide;
    [NSLayoutConstraint activateConstraints:@[
                                              [headerView.leadingAnchor constraintEqualToAnchor:readableGuide.leadingAnchor],
                                              [headerView.topAnchor constraintEqualToAnchor:headerWrapper.topAnchor],
                                              [headerView.trailingAnchor constraintEqualToAnchor:readableGuide.trailingAnchor],
                                              [headerView.bottomAnchor constraintEqualToAnchor:headerWrapper.bottomAnchor],
                                              ]];
     self.headerView = headerView;
}

#pragma mark BlogDetailHeaderViewDelegate

- (void)siteIconTapped
{
    if (![self siteIconShouldAllowDroppedImages]) {
        // Gracefully ignore the tap for users that can not upload files or
        // blogs that do not have capabilities since those will not support the REST API icon update
        return;
    }
    [WPAnalytics track:WPAnalyticsStatSiteSettingsSiteIconTapped];
    [self showUpdateSiteIconAlert];
}

- (void)siteIconReceivedDroppedImage:(UIImage *)image
{
    if (![self siteIconShouldAllowDroppedImages]) {
        // Gracefully ignore the drop for users that can not upload files or
        // blogs that do not have capabilities since those will not support the REST API icon update
        self.headerView.updatingIcon = NO;
        return;
    }
    [self presentCropViewControllerForDroppedSiteIcon:image];
}

- (BOOL)siteIconShouldAllowDroppedImages
{
    if (!self.blog.isAdmin || !self.blog.isUploadingFilesAllowed) {
        return NO;
    }
    
    return YES;
}

#pragma mark Site Icon Update Management

- (void)showUpdateSiteIconAlert
{
    UIAlertController *updateIconAlertController = [UIAlertController alertControllerWithTitle:nil
                                                                                       message:nil
                                                                                preferredStyle:UIAlertControllerStyleActionSheet];

    updateIconAlertController.popoverPresentationController.sourceView = self.headerView.blavatarImageView.superview;
    updateIconAlertController.popoverPresentationController.sourceRect = self.headerView.blavatarImageView.frame;
    updateIconAlertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [updateIconAlertController addDefaultActionWithTitle:NSLocalizedString(@"Change Site Icon", @"Change site icon button")
                                                 handler:^(UIAlertAction *action) {
                                                     [self updateSiteIcon];
                                                 }];
    if (self.blog.hasIcon) {
        [updateIconAlertController addDestructiveActionWithTitle:NSLocalizedString(@"Remove Site Icon", @"Remove site icon button")
                                                         handler:^(UIAlertAction *action) {
                                                             [self removeSiteIcon];
                                                         }];
    }
    [updateIconAlertController addCancelActionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")
                                                handler:nil];

    [self presentViewController:updateIconAlertController animated:YES completion:nil];
}

- (void)presentCropViewControllerForDroppedSiteIcon:(UIImage *)image
{
    self.imageCropViewController = [[ImageCropViewController alloc] initWithImage:image];
    self.imageCropViewController.maskShape = ImageCropOverlayMaskShapeSquare;
    self.imageCropViewController.shouldShowCancelButton = YES;
   
    __weak __typeof(self) weakSelf = self;
    self.imageCropViewController.onCancel = ^(void) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
        weakSelf.headerView.updatingIcon = NO;
    };
    
    self.imageCropViewController.onCompletion = ^(UIImage *image, BOOL modified) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
        [weakSelf uploadDroppedSiteIcon:image onCompletion:^{
            weakSelf.headerView.blavatarImageView.image = image;
            weakSelf.headerView.updatingIcon = NO;
        }];
    };
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.imageCropViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)uploadDroppedSiteIcon:(UIImage *)image onCompletion:(void(^)(void))completion
{
    if (self.blog.objectID == nil) {
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    NSProgress *mediaCreateProgress;
    [mediaService createMediaWith:image objectID:self.blog.objectID progress:&mediaCreateProgress thumbnailCallback:nil completion:^(Media *media, NSError *error) {
        if (media == nil || error != nil) {
            return;
        }
        NSProgress *uploadProgress;
        [mediaService uploadMedia:media progress:&uploadProgress success:^{
            [weakSelf updateBlogIconWithMedia:media];
            completion();
        } failure:^(NSError * _Nonnull error) {
            [weakSelf showErrorForSiteIconUpdate];
            completion();
        }];
    }];
}

- (void)updateSiteIcon
{
    self.siteIconPickerPresenter = [[SiteIconPickerPresenter alloc]initWithBlog:self.blog];
    __weak __typeof(self) weakSelf = self;
    self.siteIconPickerPresenter.onCompletion = ^(Media *media, NSError *error) {
        if (error) {
            [weakSelf showErrorForSiteIconUpdate];
        } else if (media) {
            [weakSelf updateBlogIconWithMedia:media];
        } else {
            // If no media and no error the picker was cancelled
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        }
        weakSelf.siteIconPickerPresenter = nil;
    };
    self.siteIconPickerPresenter.onIconSelection = ^() {
        weakSelf.headerView.updatingIcon = YES;
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    [self.siteIconPickerPresenter presentPickerFrom:self];
}

- (void)removeSiteIcon
{
    self.headerView.updatingIcon = YES;
    self.blog.settings.iconMediaID = @0;
    [self updateBlogSettingsAndRefreshIcon];
    [WPAnalytics track:WPAnalyticsStatSiteSettingsSiteIconRemoved];
}

- (void)updateBlogIconWithMedia:(Media *)media
{
    self.blog.settings.iconMediaID = media.mediaID;
    [self updateBlogSettingsAndRefreshIcon];
}

- (void)updateBlogSettingsAndRefreshIcon
{
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.blog.managedObjectContext];
    [blogService updateSettingsForBlog:self.blog
                               success:^{
        [blogService syncBlog:self.blog
                      success:^{
            self.headerView.updatingIcon = NO;
            [self.headerView refreshIconImage];
        } failure:nil];
     } failure:^(NSError *error){
         [self showErrorForSiteIconUpdate];
     }];
}

- (void)showErrorForSiteIconUpdate
{
    [SVProgressHUD showDismissibleErrorWithStatus:NSLocalizedString(@"Icon update failed", @"Message to show when site icon update failed")];
    self.headerView.updatingIcon = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    BlogDetailsSection *detailSection = [self.tableSections objectAtIndex:section];
    return [detailSection.rows count];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    BlogDetailsSection *section = [self.tableSections objectAtIndex:indexPath.section];
    BlogDetailsRow *row = [section.rows objectAtIndex:indexPath.row];
    cell.textLabel.text = row.title;
    cell.accessibilityIdentifier = row.accessibilityIdentifier ?: row.identifier;
    cell.detailTextLabel.text = row.detail;
    cell.imageView.image = row.image;
    if (row.accessoryView) {
        cell.accessoryView = row.accessoryView;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BlogDetailsSection *section = [self.tableSections objectAtIndex:indexPath.section];
    BlogDetailsRow *row = [section.rows objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:row.identifier];
    cell.accessoryView = nil;
    cell.textLabel.textAlignment = NSTextAlignmentNatural;
    cell.imageView.tintColor = [WPStyleGuide greyLighten10];
    if (row.forDestructiveAction) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [WPStyleGuide configureTableViewDestructiveActionCell:cell];
    } else {
        cell.accessoryType = [self splitViewControllerIsHorizontallyCompact] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
        [WPStyleGuide configureTableViewCell:cell];
    }
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BlogDetailsSection *section = [self.tableSections objectAtIndex:indexPath.section];
    BlogDetailsRow *row = [section.rows objectAtIndex:indexPath.row];
    row.callback();

    if (row.showsSelectionState) {
        self.restorableSelectedIndexPath = indexPath;
    } else if (![self splitViewControllerIsHorizontallyCompact]) {
        // Reselect the previous row
        [tableView selectRowAtIndexPath:self.restorableSelectedIndexPath
                               animated:YES
                         scrollPosition:UITableViewScrollPositionNone];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    BlogDetailsSection *detailSection = [self.tableSections objectAtIndex:section];
    return detailSection.title;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    [WPStyleGuide configureTableViewSectionHeader:view];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    BOOL isNewSelection = (indexPath != tableView.indexPathForSelectedRow);
    
    if (isNewSelection) {
        return indexPath;
    } else {
        return nil;
    }
}

#pragma mark - Private methods


- (void)preloadBlogData
{
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedInstance];
    BOOL isOnWifi = [appDelegate.internetReachability isReachableViaWiFi];
    
    // only preload on wifi
    if (isOnWifi) {
        [self preloadStats];
        [self preloadPosts];
        [self preloadPages];
        [self preloadComments];
    }
}

- (void)preloadStats
{
    NSString *oauthToken = self.blog.authToken;
    
    if (oauthToken) {
        self.statsService = [[WPStatsService alloc] initWithSiteId:self.blog.dotComID siteTimeZone:[self.blogService timeZoneForBlog:self.blog] oauth2Token:oauthToken andCacheExpirationInterval:5 * 60];
        [self.statsService retrieveInsightsStatsWithAllTimeStatsCompletionHandler:nil insightsCompletionHandler:nil todaySummaryCompletionHandler:nil latestPostSummaryCompletionHandler:nil commentsAuthorCompletionHandler:nil commentsPostsCompletionHandler:nil tagsCategoriesCompletionHandler:nil followersDotComCompletionHandler:nil followersEmailCompletionHandler:nil publicizeCompletionHandler:nil streakCompletionHandler:nil progressBlock:nil andOverallCompletionHandler:nil];
    }
}

- (void)preloadPosts
{
    [self preloadPostsOfType:PostServiceTypePost];
}

- (void)preloadPages
{
    [self preloadPostsOfType:PostServiceTypePage];
}

// preloads posts or pages.
- (void)preloadPostsOfType:(PostServiceType)postType
{
    // Temporarily disable posts preloading until we can properly resolve the issues on:
    // https://github.com/wordpress-mobile/WordPress-iOS/issues/6151
    // Brent C. Nov 3/2016
    BOOL preloadingPostsDisabled = YES;
    if (preloadingPostsDisabled) {
        return;
    }

    NSDate *lastSyncDate;
    if ([postType isEqual:PostServiceTypePage]) {
        lastSyncDate = self.blog.lastPagesSync;
    } else {
        lastSyncDate = self.blog.lastPostsSync;
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
    NSTimeInterval lastSync = lastSyncDate.timeIntervalSinceReferenceDate;
    if (now - lastSync > PreloadingCacheTimeout) {
        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
        PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
        PostListFilterSettings *filterSettings = [[PostListFilterSettings alloc] initWithBlog:self.blog postType:postType];
        PostListFilter *filter = [filterSettings currentPostListFilter];

        PostServiceSyncOptions *options = [PostServiceSyncOptions new];
        options.statuses = filter.statuses;
        options.authorID = [filterSettings authorIDFilter];
        options.purgesLocalSync = YES;

        if ([postType isEqual:PostServiceTypePage]) {
            self.blog.lastPagesSync = [NSDate date];
        } else {
            self.blog.lastPostsSync = [NSDate date];
        }
        NSError *error = nil;
        [self.blog.managedObjectContext save:&error];

        [postService syncPostsOfType:postType withOptions:options forBlog:self.blog success:nil failure:^(NSError *error) {
            NSDate *invalidatedDate = [NSDate dateWithTimeIntervalSince1970:0.0];
            if ([postType isEqual:PostServiceTypePage]) {
                self.blog.lastPagesSync = invalidatedDate;
            } else {
                self.blog.lastPostsSync = invalidatedDate;
            }
        }];
    }
}

- (void)preloadComments
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:context];

    if ([CommentService shouldRefreshCacheFor:self.blog]) {
        [commentService syncCommentsForBlog:self.blog success:nil failure:nil];
    }
}

- (void)showComments
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedComments withBlog:self.blog];
    CommentsViewController *controller = [[CommentsViewController alloc] initWithStyle:UITableViewStylePlain];
    controller.blog = self.blog;
    [self showDetailViewController:controller sender:self];
}

- (void)showPostList
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPosts withBlog:self.blog];
    PostListViewController *controller = [PostListViewController controllerWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];
}

- (void)showPageList
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPages withBlog:self.blog];
    PageListViewController *controller = [PageListViewController controllerWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];
}

- (void)showMediaLibrary
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedMediaLibrary withBlog:self.blog];
    MediaLibraryViewController *controller = [[MediaLibraryViewController alloc] initWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];
}

- (void)showPeople
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPeople withBlog:self.blog];
    PeopleViewController *controller = [PeopleViewController controllerWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];
}

- (void)showPlugins
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPluginDirectory withBlog:self.blog];
    PluginDirectoryViewController *controller = [[PluginDirectoryViewController alloc] initWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];
}

- (void)showPlans
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPlans withBlog:self.blog];
    PlanListViewController *controller = [[PlanListViewController alloc] initWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];
}

- (void)showSettings
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedSiteSettings withBlog:self.blog];
    SiteSettingsViewController *controller = [[SiteSettingsViewController alloc] initWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];
}

- (void)showSharing
{
    UIViewController *controller;
    if (![self.blog supportsPublicize]) {
        // if publicize is disabled, show the sharing buttons settings.
        controller = [[SharingButtonsViewController alloc] initWithBlog:self.blog];

    } else {
        controller = [[SharingViewController alloc] initWithBlog:self.blog];
    }

    [WPAppAnalytics track:WPAnalyticsStatOpenedSharingManagement withBlog:self.blog];
    [self showDetailViewController:controller sender:self];
}

- (void)showStats
{
    [WPAppAnalytics track:WPAnalyticsStatStatsAccessed withBlog:self.blog];
    StatsViewController *statsView = [StatsViewController new];
    statsView.blog = self.blog;
    statsView.statsService = self.statsService;

    // Calling `showDetailViewController:sender:` should do this automatically for us,
    // but when showing stats from our 3D Touch shortcut iOS sometimes incorrectly
    // presents the stats view controller as modal instead of pushing it. As a
    // workaround for now, we'll manually decide whether to push or use `showDetail`.
    // @frosty 2016-09-05
    if (self.splitViewController.isCollapsed) {
        [self.navigationController pushViewController:statsView animated:YES];
    } else {
        [self showDetailViewController:statsView sender:self];
    }
}

- (void)startTour
{
    [QuickStartTourGuide.shared showTestQuickStartNotice];
}

- (void)showActivity
{
    ActivityListViewController *controller = [[ActivityListViewController alloc] initWithBlog:self.blog];
    [self showDetailViewController:controller sender:self];
}

- (void)showThemes
{
    [WPAppAnalytics track:WPAnalyticsStatThemesAccessedThemeBrowser withBlog:self.blog];
    ThemeBrowserViewController *viewController = [ThemeBrowserViewController browserWithBlog:self.blog];
    [self showDetailViewController:viewController sender:self];
}

- (void)showMenus
{
    [WPAppAnalytics track:WPAnalyticsStatMenusAccessed withBlog:self.blog];
    MenusViewController *viewController = [MenusViewController controllerWithBlog:self.blog];
    [self showDetailViewController:viewController sender:self];
}

- (void)showViewSite
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedViewSite withBlog:self.blog];
    NSURL *targetURL = [NSURL URLWithString:self.blog.homeURL];

    if (self.blog.jetpack) {
        targetURL = [targetURL appendingHideMasterbarParameters];
    }
    
    UIViewController *webViewController = [WebViewControllerFactory controllerWithUrl:targetURL blog:self.blog];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)showViewAdmin
{
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }

    [WPAppAnalytics track:WPAnalyticsStatOpenedViewAdmin withBlog:self.blog];

    NSString *dashboardUrl;
    if (self.blog.isHostedAtWPcom) {
        dashboardUrl = [NSString stringWithFormat:@"%@%@", WPCalypsoDashboardPath, self.blog.hostname];
    } else {
        dashboardUrl = [self.blog adminUrlWithPath:@""];
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dashboardUrl] options:nil completionHandler:nil];
}

- (void)showNotificationPrimerAlert
{
    if ([[NSUserDefaults standardUserDefaults] notificationPrimerAlertWasDisplayed]) {
        return;
    }
    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:mainContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    if (defaultAccount == nil) {
        return;
    }
    [[PushNotificationsManager shared] loadAuthorizationStatusWithCompletion:^(UNAuthorizationStatus enabled) {
        if (enabled == UNAuthorizationStatusNotDetermined) {
            [NSUserDefaults standardUserDefaults].notificationPrimerAlertWasDisplayed = YES;

            FancyAlertViewController *alert = [FancyAlertViewController makeNotificationPrimerAlertControllerWithApproveAction:^(FancyAlertViewController* controller) {
                [[InteractiveNotificationsManager shared] requestAuthorizationWithCompletion:^() {
                    [controller dismissViewControllerAnimated:true completion:^{}];
                }];
            }];
            alert.modalPresentationStyle = UIModalPresentationCustom;
            alert.transitioningDelegate = self;

            [self.tabBarController presentViewController:alert animated:YES completion:nil];
        }
    }];
}

#pragma mark - Remove Site

- (void)showRemoveSiteAlert
{
    NSString *model = [[UIDevice currentDevice] localizedModel];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to continue?\n All site data will be removed from your %@.", @"Title for the remove site confirmation alert, %@ will be replaced with iPhone/iPad/iPod Touch"), model];
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    NSString *destructiveTitle = NSLocalizedString(@"Remove Site", @"Button to remove a site from the app");

    UIAlertControllerStyle alertStyle = [UIDevice isPad] ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:alertStyle];

    [alertController addCancelActionWithTitle:cancelTitle handler:nil];
    [alertController addDestructiveActionWithTitle:destructiveTitle handler:^(UIAlertAction *action) {
        [self confirmRemoveSite];
    }];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)confirmRemoveSite
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService removeBlog:self.blog];
    [[WordPressAppDelegate sharedInstance] trackLogoutIfNeeded];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Notification handlers

- (void)handleDataModelChange:(NSNotification *)note
{
    NSSet *deletedObjects = note.userInfo[NSDeletedObjectsKey];
    if ([deletedObjects containsObject:self.blog]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }

    NSSet *updatedObjects = note.userInfo[NSUpdatedObjectsKey];
    if ([updatedObjects containsObject:self.blog] || [updatedObjects containsObject:self.blog.settings]) {
        self.navigationItem.title = self.blog.settings.name;
        [self reloadTableViewPreservingSelection];
    }
}

#pragma mark - WPSplitViewControllerDetailProvider

- (UIViewController *)initialDetailViewControllerForSplitView:(WPSplitViewController *)splitView
{
    StatsViewController *statsView = [StatsViewController new];
    statsView.blog = self.blog;
    statsView.statsService = self.statsService;

    return statsView;
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
