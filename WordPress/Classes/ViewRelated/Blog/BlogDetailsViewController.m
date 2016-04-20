#import "BlogDetailsViewController.h"

#import "AccountService.h"
#import "BlogService.h"
#import "BlogDetailHeaderView.h"
#import "CommentsViewController.h"
#import "ContextManager.h"
#import "PostListViewController.h"
#import "PageListViewController.h"
#import "ReachabilityUtils.h"
#import "SiteSettingsViewController.h"
#import "SharingViewController.h"
#import "StatsViewController.h"
#import "WPAccount.h"
#import "WPAppAnalytics.h"
#import "WPGUIConstants.h"
#import "WPStyleGuide+ReadableMargins.h"
#import "WPTableViewCell.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "WPWebViewController.h"
#import "WordPress-Swift.h"

static NSString *const BlogDetailsCellIdentifier = @"BlogDetailsCell";
static NSString *const BlogDetailsPlanCellIdentifier = @"BlogDetailsPlanCell";

NSString * const WPBlogDetailsRestorationID = @"WPBlogDetailsID";
NSString * const WPBlogDetailsBlogKey = @"WPBlogDetailsBlogKey";
NSInteger const BlogDetailHeaderViewHorizontalMarginiPhone = 15;
NSInteger const BlogDetailHeaderViewVerticalMargin = 18;
NSString * const BlogDetailAccountHideViewAdminTimeZone = @"GMT";
NSInteger const BlogDetailAccountHideViewAdminYear = 2015;
NSInteger const BlogDetailAccountHideViewAdminMonth = 9;
NSInteger const BlogDetailAccountHideViewAdminDay = 7;


#pragma mark - Helper Classes for Blog Details view model.

@interface BlogDetailsRow : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, copy) void (^callback)();

@end

@implementation BlogDetailsRow

- (instancetype)initWithTitle:(NSString * __nonnull)title
                        image:(UIImage * __nonnull)image
                     callback:(void(^)())callback
{
    return [self initWithTitle:title
                    identifier:BlogDetailsCellIdentifier
                         image:image
                      callback:callback];
}

- (instancetype)initWithTitle:(NSString * __nonnull)title
                   identifier:(NSString * __nonnull)identifier 
                        image:(UIImage * __nonnull)image
                     callback:(void(^)())callback
{
    self = [super init];
    if (self) {
        _title = title;
        _image = image;
        _callback = callback;
        _identifier = identifier;
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

@interface BlogDetailsViewController () <UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) BlogDetailHeaderView *headerView;
@property (nonatomic, strong) NSArray *headerViewHorizontalConstraints;
@property (nonatomic, strong) NSArray *tableSections;

@end

@implementation BlogDetailsViewController

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

    BlogDetailsViewController *viewController = [[self alloc] initWithStyle:UITableViewStyleGrouped];
    viewController.blog = restoredBlog;

    return viewController;
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

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[[self.blog.objectID URIRepresentation] absoluteString] forKey:WPBlogDetailsBlogKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [WPStyleGuide resetReadableMarginsForTableView:self.tableView];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:BlogDetailsCellIdentifier];
    [self.tableView registerClass:[WPTableViewCellValue1 class] forCellReuseIdentifier:BlogDetailsPlanCellIdentifier];

    __weak __typeof(self) weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncBlog:_blog completionHandler:^() {
        [weakSelf configureTableViewData];
        [weakSelf.tableView reloadData];
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

    [self.headerView setBlog:self.blog];
    [self updateHeaderViewConstraintsForTraitCollection:self.traitCollection];

    // Configure and reload table data when appearing to ensure pending comment count is updated
    [self configureTableViewData];
    [self.tableView reloadData];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateHeaderViewConstraintsForTraitCollection:newCollection];
    } completion:nil];
}


#pragma mark - Data Model setup


- (void)configureTableViewData
{
    NSMutableArray *marr = [NSMutableArray array];
    [marr addObject:[self generalSectionViewModel]];
    [marr addObject:[self publishTypeSectionViewModel]];
    if ([self.blog supports:BlogFeatureThemeBrowsing]) {
        [marr addObject:[self appearanceSectionViewModel]];
    }
    [marr addObject:[self configurationSectionViewModel]];

    // Assign non mutable copy.
    self.tableSections = [NSArray arrayWithArray:marr];
}

- (BlogDetailsSection *)generalSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"View Site", @"Action title. Opens the user's site in an in-app browser")
                                                    image:[UIImage imageNamed:@"icon-menu-viewsite"]
                                                 callback:^{
                                                     [weakSelf showViewSite];
                                                 }]];

    if ([self shouldShowWPAdminRow]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"WP Admin", @"Action title. Noun. Opens the user's WordPress Admin in an external browser.")
                                                        image:[UIImage imageNamed:@"icon-menu-viewadmin"]
                                                     callback:^{
                                                         [weakSelf showViewAdmin];
                                                     }]];
    }

    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Stats", @"Noun. Abbv. of Statistics. Links to a blog's Stats screen.")
                                                    image:[UIImage imageNamed:@"icon-menu-stats"]
                                                 callback:^{
                                                     [weakSelf showStats];
                                                 }]];

    if ([Feature enabled:FeatureFlagPlans] && [self.blog supports:BlogFeaturePlans]) {
        BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Plans", @"Action title. Noun. Links to a blog's Plans screen.")
                                                         identifier:BlogDetailsPlanCellIdentifier
                                                              image:[UIImage imageNamed:@"icon-menu-plans"]
                                                           callback:^{
                                                               [weakSelf showPlans];
                                                           }];

        row.detail = [PlansBridge titleForPlanWithID:[self.blog.planID integerValue]];

        [rows addObject:row];
    }
    
    return [[BlogDetailsSection alloc] initWithTitle:nil andRows:rows];
}

- (BlogDetailsSection *)publishTypeSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Blog Posts", @"Noun. Title. Links to the blog's Posts screen.")
                                                    image:[UIImage imageNamed:@"icon-menu-posts"]
                                                 callback:^{
                                                     [weakSelf showPostList];
                                                 }]];

    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Pages", @"Noun. Title. Links to the blog's Pages screen.")
                                                    image:[UIImage imageNamed:@"icon-menu-pages"]
                                                 callback:^{
                                                     [weakSelf showPageList];
                                                 }]];

    BlogDetailsRow *row = [[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Comments", @"Noun. Title. Links to the blog's Comments screen.")
                                                          image:[UIImage imageNamed:@"icon-menu-comments"]
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

- (BlogDetailsSection *)appearanceSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];
    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Themes", @"Themes option in the blog details")
                                                    image:[UIImage imageNamed:@"icon-menu-theme"]
                                                 callback:^{
                                                     [weakSelf showThemes];
                                                 }]];

    NSString *title =NSLocalizedString(@"Personalize", @"Section title for the personalize table section in the blog details screen.");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows];
}

- (BlogDetailsSection *)configurationSectionViewModel
{
    __weak __typeof(self) weakSelf = self;
    NSMutableArray *rows = [NSMutableArray array];

    if ([self.blog supports:BlogFeatureSharing]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Sharing", @"Noun. Title. Links to a blog's sharing options.")
                                                        image:[UIImage imageNamed:@"icon-menu-sharing"]
                                                     callback:^{
                                                         [weakSelf showSharing];
                                                     }]];
    }

    if ([Feature enabled:FeatureFlagPeople] && [self.blog supports:BlogFeaturePeople]) {
        [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"People", @"Noun. Title. Links to the people management feature.")
                                                        image:[UIImage imageNamed:@"icon-menu-people"]
                                                     callback:^{
                                                         [weakSelf showPeople];
                                                     }]];
    }

    [rows addObject:[[BlogDetailsRow alloc] initWithTitle:NSLocalizedString(@"Settings", @"Noun. Title. Links to the blog's Settings screen.")
                                                    image:[UIImage imageNamed:@"icon-menu-settings"]
                                                 callback:^{
                                                     [weakSelf showSettings];
                                                 }]];

    NSString *title = NSLocalizedString(@"Configure", @"Section title for the configure table section in the blog details screen");
    return [[BlogDetailsSection alloc] initWithTitle:title andRows:rows];
}


#pragma mark - Configuration

- (void)configureBlogDetailHeader
{
    // Wrapper view
    UIView *headerWrapper = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), BlogDetailHeaderViewBlavatarSize + BlogDetailHeaderViewVerticalMargin * 2)];
    self.tableView.tableHeaderView = headerWrapper;

    // Blog detail header view
    self.headerView = [[BlogDetailHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), BlogDetailHeaderViewBlavatarSize)];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [headerWrapper addSubview:self.headerView];

    NSDictionary *views = NSDictionaryOfVariableBindings(_headerView);
    NSDictionary *metrics = @{@"verticalMargin": @(BlogDetailHeaderViewVerticalMargin)};

    // Constrain the headerView vertically
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(verticalMargin)-[_headerView]-(verticalMargin)-|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
}

- (void)updateHeaderViewConstraintsForTraitCollection:(UITraitCollection *)traitCollection
{
    UIView *headerWrapper = self.tableView.tableHeaderView;

    // We only remove the constraints we've added, not the view's autoresizing constraints
    [headerWrapper removeConstraints:self.headerViewHorizontalConstraints];

    if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact || traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        NSDictionary *views = NSDictionaryOfVariableBindings(_headerView);
        NSDictionary *metrics = @{@"horizontalMargin": @(BlogDetailHeaderViewHorizontalMarginiPhone)};

        self.headerViewHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-(horizontalMargin)-[_headerView]-(horizontalMargin)-|"
                                                                                       options:0
                                                                                       metrics:metrics
                                                                                         views:views];
    } else {
        NSMutableArray *constraints = [NSMutableArray new];

        CGFloat headerWidth = WPTableViewFixedWidth;
        [constraints addObject:[self.headerView.widthAnchor constraintEqualToConstant:headerWidth]];

        // Center the headerView inside the wrapper
        [constraints addObject:[self.headerView.centerXAnchor constraintEqualToAnchor:headerWrapper.centerXAnchor]];

        self.headerViewHorizontalConstraints = [constraints copy];
    }

    [headerWrapper addConstraints:self.headerViewHorizontalConstraints];
    [headerWrapper layoutIfNeeded];
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
    cell.detailTextLabel.text = row.detail;
    cell.imageView.image = row.image;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BlogDetailsSection *section = [self.tableSections objectAtIndex:indexPath.section];
    BlogDetailsRow *row = [section.rows objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:row.identifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    [WPStyleGuide configureTableViewCell:cell];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    BlogDetailsSection *section = [self.tableSections objectAtIndex:indexPath.section];
    BlogDetailsRow *row = [section.rows objectAtIndex:indexPath.row];
    row.callback();
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return WPTableViewDefaultRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderFooterView heightForHeader:title width:CGRectGetWidth(self.view.bounds)];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    if (title.length == 0) {
        return nil;
    }

    WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithReuseIdentifier:nil style:WPTableViewSectionStyleHeader];
    header.title = title;
    return header;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    BlogDetailsSection *detailSection = [self.tableSections objectAtIndex:section];
    return detailSection.title;
}

#pragma mark - Private methods

- (void)showComments
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedComments withBlog:self.blog];
    CommentsViewController *controller = [[CommentsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    controller.blog = self.blog;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showPostList
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPosts withBlog:self.blog];
    PostListViewController *controller = [PostListViewController controllerWithBlog:self.blog];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showPageList
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedPages withBlog:self.blog];
    PageListViewController *controller = [PageListViewController controllerWithBlog:self.blog];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showPeople
{
    // TODO(@koke, 2015-11-02): add analytics
    PeopleViewController *controller = [[UIStoryboard storyboardWithName:@"People" bundle:nil] instantiateInitialViewController];
    controller.blog = self.blog;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showPlans
{
    // TODO(@koke, 2016-01-28): add analytics
    PlanListViewController *controller = [[PlanListViewController alloc] initWithBlog:self.blog];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showSettings
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedSiteSettings withBlog:self.blog];
    SiteSettingsViewController *controller = [[SiteSettingsViewController alloc] initWithBlog:self.blog];
    [self.navigationController pushViewController:controller animated:YES];
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

    //TODO: (@aerych, 2016-01-14) Add tracker for sharing feature
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showStats
{
    [WPAppAnalytics track:WPAnalyticsStatStatsAccessed withBlog:self.blog];
    StatsViewController *statsView = [StatsViewController new];
    statsView.blog = self.blog;
    [self.navigationController pushViewController:statsView animated:YES];
}

- (void)showThemes
{
    [WPAppAnalytics track:WPAnalyticsStatThemesAccessedThemeBrowser withBlog:self.blog];
    ThemeBrowserViewController *viewController = [ThemeBrowserViewController browserWithBlog:self.blog];
    [self.navigationController pushViewController:viewController
                                         animated:YES];
}

- (void)showViewSite
{
    [WPAppAnalytics track:WPAnalyticsStatOpenedViewSite withBlog:self.blog];
    NSURL *targetURL = [NSURL URLWithString:self.blog.homeURL];
    WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:targetURL];
    webViewController.authToken = self.blog.authToken;
    webViewController.username = self.blog.usernameForSite;
    webViewController.password = self.blog.password;
    webViewController.wpLoginURL = [NSURL URLWithString:self.blog.loginUrl];

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

    NSString *dashboardUrl = [self.blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@"wp-admin/"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dashboardUrl]];
}

- (BOOL)shouldShowWPAdminRow
{
    return !self.blog.isHostedAtWPcom || [self wasAccountCreateBeforeHideViewAdminDate];
}

- (BOOL)wasAccountCreateBeforeHideViewAdminDate
{
    NSDate *hideViewAdminDate = [self hideViewAdminDate];
    WPAccount *account = self.blog.account;
    
    return [account.dateCreated compare:hideViewAdminDate] == NSOrderedAscending;
}

- (NSDate *)hideViewAdminDate
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone timeZoneWithName:BlogDetailAccountHideViewAdminTimeZone];
    
    NSDateComponents *hideAdminDateComponents = [NSDateComponents new];
    hideAdminDateComponents.year = BlogDetailAccountHideViewAdminYear;
    hideAdminDateComponents.month = BlogDetailAccountHideViewAdminMonth;
    hideAdminDateComponents.day = BlogDetailAccountHideViewAdminDay;
    
    return [calendar dateFromComponents:hideAdminDateComponents];
}


#pragma mark - Notification handlers

- (void)handleDataModelChange:(NSNotification *)note
{
    NSSet *deletedObjects = note.userInfo[NSDeletedObjectsKey];
    if ([deletedObjects containsObject:self.blog]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }

    NSSet *updatedObjects = note.userInfo[NSUpdatedObjectsKey];
    if ([updatedObjects containsObject:self.blog]) {
        self.navigationItem.title = self.blog.settings.name;
        [self.tableView reloadData];
    }
}

@end
