// Blog Details contents:
//
// + (No Title)
// | View Site
// | WP Admin
// | Stats
//
// + Publish
// | Blog Posts
// | Pages
// | Comments
//
// + Configuration
// | Edit Site

#import "BlogDetailsViewController.h"
#import "SiteSettingsViewController.h"
#import "CommentsViewController.h"
#import "ThemeBrowserViewController.h"
#import "StatsViewController.h"
#import "WPWebViewController.h"
#import "WPTableViewCell.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "BlogService.h"
#import "WPTableViewSectionHeaderFooterView.h"
#import "BlogDetailHeaderView.h"
#import "ReachabilityUtils.h"
#import "WPAccount.h"
#import "PostListViewController.h"
#import "PageListViewController.h"
#import "WPThemeSettings.h"
#import "WPGUIConstants.h"

const NSInteger BlogDetailsRowViewSite = 0;
const NSInteger BlogDetailsRowViewAdmin = 1;
const NSInteger BlogDetailsRowStats = 2;
const NSInteger BlogDetailsRowBlogPosts = 0;
const NSInteger BlogDetailsRowPages = 1;
const NSInteger BlogDetailsRowComments = 2;
const NSInteger BlogDetailsRowEditSite = 0;

typedef NS_ENUM(NSInteger, TableSectionContentType) {
    TableViewSectionGeneralType = 0,
    TableViewSectionPublishType,
    TableViewSectionAppearance,
    TableViewSectionConfigurationType,
    TableViewSectionCount
};

static NSString *const BlogDetailsCellIdentifier = @"BlogDetailsCell";
NSString * const WPBlogDetailsRestorationID = @"WPBlogDetailsID";
NSString * const WPBlogDetailsBlogKey = @"WPBlogDetailsBlogKey";
NSInteger const BlogDetailHeaderViewHorizontalMarginiPhone = 15;
NSInteger const BlogDetailHeaderViewVerticalMargin = 18;

NSInteger const BlogDetailsRowCountForSectionGeneralType = 3;
NSInteger const BlogDetailsRowCountForSectionPublishType = 3;
NSInteger const BlogDetailsRowCountForSectionAppearance = 1;
NSInteger const BlogDetailsRowCountForSectionConfigurationType = 1;

@interface BlogDetailsViewController () <UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) BlogDetailHeaderView *headerView;
@property (nonatomic, weak) UIActionSheet *removeSiteActionSheet;
@property (nonatomic, weak) UIAlertView *removeSiteAlertView;

/**
 *  @brief      Property to store the themes-enabled state when the VC opens.
 *  @details    The reason it's important to store this in a property as opposed to checking if
 *              themes are enabled in real time, is that this VC is not ready to update the themes
 *              feature visibility if it's changed when this VC is open.  This is not a big problem
 *              though since this feature exists only for testing purposes, but it could still crash
 *              the app if not handled properly.
 */
@property (nonatomic, assign, readwrite, getter=areThemesEnabled) BOOL themesEnabled;

@end

@implementation BlogDetailsViewController
@synthesize blog = _blog;

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

- (void)dealloc
{
    self.removeSiteActionSheet.delegate = nil;
    self.removeSiteAlertView.delegate = nil;
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
    
    self.themesEnabled = [WPThemeSettings isEnabled];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:BlogDetailsCellIdentifier];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncBlog:_blog];
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

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:self.blog.blogName style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
}

- (void)configureBlogDetailHeader
{
    // Wrapper view
    UIView *headerWrapper = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), BlogDetailHeaderViewBlavatarSize + BlogDetailHeaderViewVerticalMargin * 2)];
    self.tableView.tableHeaderView = headerWrapper;
    
    // Blog detail header view
    self.headerView = [[BlogDetailHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), BlogDetailHeaderViewBlavatarSize)];
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [headerWrapper addSubview:self.headerView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_headerView, headerWrapper);
    NSDictionary *metrics = @{@"horizontalMargin": @(BlogDetailHeaderViewHorizontalMarginiPhone),
                              @"verticalMargin": @(BlogDetailHeaderViewVerticalMargin)};

    if (IS_IPAD) {
        // Set the header width
        CGFloat headerWidth = WPTableViewFixedWidth;
        [headerWrapper addConstraint:[NSLayoutConstraint constraintWithItem:self.headerView
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1.0
                                                                   constant:headerWidth]];
        // Center the headerView inside the wrapper
        [headerWrapper addConstraint:[NSLayoutConstraint constraintWithItem:self.headerView
                                                                  attribute:NSLayoutAttributeCenterX
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:headerWrapper
                                                                  attribute:NSLayoutAttributeCenterX
                                                                 multiplier:1.0
                                                                   constant:0.0]];
    } else {
        // Pin the headerWrapper to its superview AND wrap the headerView in horizontal margins
        [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(horizontalMargin)-[_headerView]-(horizontalMargin)-|"
                                                                              options:0
                                                                              metrics:metrics
                                                                                views:views]];
    }

    // Constrain the headerWrapper and headerView vertically
    [headerWrapper addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(verticalMargin)-[_headerView]-(verticalMargin)-|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.headerView setBlog:self.blog];
    [self.tableView reloadData];
}

- (void)setBlog:(Blog *)blog
{
    _blog = blog;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger result = TableViewSectionCount;    
    
    if (!self.areThemesEnabled) {
        result -= 1;
    }
    
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isGeneralSection:section]) {
        return BlogDetailsRowCountForSectionGeneralType;
    } else if ([self isPublishSection:section]) {
        return BlogDetailsRowCountForSectionPublishType;
    } else if ([self isAppearanceSection:section]) {
        return BlogDetailsRowCountForSectionAppearance;
    } else if ([self isConfigurationSection:section]) {
        return BlogDetailsRowCountForSectionConfigurationType;
    }

    return 0;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self isGeneralSection:indexPath.section]) {
        switch (indexPath.row) {
            case BlogDetailsRowViewSite:
                cell.textLabel.text = NSLocalizedString(@"View Site", nil);
                cell.imageView.image = [UIImage imageNamed:@"icon-menu-viewsite"];
                break;
            case BlogDetailsRowViewAdmin:
                cell.textLabel.text = NSLocalizedString(@"WP Admin", nil);
                cell.imageView.image = [UIImage imageNamed:@"icon-menu-viewadmin"];
                break;
            case BlogDetailsRowStats:
                cell.textLabel.text = NSLocalizedString(@"Stats", nil);
                cell.imageView.image = [UIImage imageNamed:@"icon-menu-stats"];
                break;
            default:
                break;
        }
    } else if ([self isPublishSection:indexPath.section]) {
        switch (indexPath.row) {
            case BlogDetailsRowBlogPosts:
                cell.textLabel.text = NSLocalizedString(@"Blog Posts", nil);
                cell.imageView.image = [UIImage imageNamed:@"icon-menu-posts"];
                break;
            case BlogDetailsRowPages:
                cell.textLabel.text = NSLocalizedString(@"Pages", nil);
                cell.imageView.image = [UIImage imageNamed:@"icon-menu-pages"];
                break;
            case BlogDetailsRowComments:
                cell.textLabel.text = NSLocalizedString(@"Comments", nil);
                cell.imageView.image = [UIImage imageNamed:@"icon-menu-comments"];
                NSUInteger numberOfPendingComments = [self.blog numberOfPendingComments];
                if (numberOfPendingComments > 0) {
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", numberOfPendingComments];
                }
                break;
            default:
                break;
        }
    } else if ([self isAppearanceSection:indexPath.section]) {
        cell.textLabel.text = NSLocalizedString(@"Themes", @"Themes option in the blog details");
        cell.imageView.image = [UIImage imageNamed:@"icon-menu-theme"];
    } else if ([self isConfigurationSection:indexPath.section]) {
        if (indexPath.row == BlogDetailsRowEditSite) {
            cell.textLabel.text = NSLocalizedString(@"Settings", nil);
            cell.imageView.image = [UIImage imageNamed:@"icon-menu-settings"];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BlogDetailsCellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    [WPStyleGuide configureTableViewCell:cell];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([self isConfigurationSection:indexPath.section]) {
        switch (indexPath.row) {
            case BlogDetailsRowEditSite:
                [self showSettingsForBlog:self.blog];
                break;
            default:
                NSAssert(false, @"Row Handling not implemented");
                break;
        }
    } else if ([self isGeneralSection:indexPath.section]) {
        switch (indexPath.row) {
            case BlogDetailsRowViewSite:
                [self showViewSiteForBlog:self.blog];
                break;
            case BlogDetailsRowViewAdmin:
                [self showViewAdminForBlog:self.blog];
                break;
            case BlogDetailsRowStats:
                [self showStatsForBlog:self.blog];
                break;
            default:
                NSAssert(false, @"Row Handling not implemented");
                break;
        }
    } else if ([self isPublishSection:indexPath.section]) {
        switch (indexPath.row) {
            case BlogDetailsRowBlogPosts:
                [self showPostListForBlog:self.blog];
                return;
            case BlogDetailsRowPages:
                [self showPageListForBlog:self.blog];
                return;
            case BlogDetailsRowComments:
                [self showCommentsForBlog:self.blog];
                break;
            default:
                NSAssert(false, @"Row Handling not implemented");
                break;
        }
    }
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
    NSString *headingTitle = nil;
    if ([self isPublishSection:section]) {
        headingTitle = NSLocalizedString(@"Publish", @"");
    } else if ([self isAppearanceSection:section]) {
        headingTitle = NSLocalizedString(@"Appearance",
                                         @"Section title for the appearance table section in the" \
                                         " blog details screen.");
    } else if ([self isConfigurationSection:section]) {
        headingTitle = NSLocalizedString(@"Configuration", @"");
    }

    return headingTitle;
}

#pragma mark - Identifying sections

- (BOOL)isGeneralSection:(NSInteger)section
{
    return section == TableViewSectionGeneralType;
}

- (BOOL)isPublishSection:(NSInteger)section
{
    return section == TableViewSectionPublishType;
}

- (BOOL)isAppearanceSection:(NSInteger)section
{
    return self.areThemesEnabled && section == TableViewSectionAppearance;
}

- (BOOL)isConfigurationSection:(NSInteger)section
{
    if (!self.areThemesEnabled) {
        section += 1;
    }
    
    return section == TableViewSectionConfigurationType;
}

#pragma mark - Private methods

- (void)showCommentsForBlog:(Blog *)blog
{
    [WPAnalytics track:WPAnalyticsStatOpenedComments];
    CommentsViewController *controller = [[CommentsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    controller.blog = blog;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showPostListForBlog:(Blog *)blog
{
    [WPAnalytics track:WPAnalyticsStatOpenedPosts];
    PostListViewController *controller = [PostListViewController controllerWithBlog:blog];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showPageListForBlog:(Blog *)blog
{
    [WPAnalytics track:WPAnalyticsStatOpenedPages];
    PageListViewController *controller = [PageListViewController controllerWithBlog:blog];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showSettingsForBlog:(Blog *)blog
{
    [WPAnalytics track:WPAnalyticsStatOpenedSettings];
    SiteSettingsViewController *controller = [[SiteSettingsViewController alloc] initWithBlog:blog];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showStatsForBlog:(Blog *)blog
{
    [WPAnalytics track:WPAnalyticsStatStatsAccessed];
    StatsViewController *statsView = [StatsViewController new];
    statsView.blog = blog;
    [self.navigationController pushViewController:statsView animated:YES];
}

- (void)showViewSiteForBlog:(Blog *)blog
{
    [WPAnalytics track:WPAnalyticsStatOpenedViewSite];

    NSURL *targetURL = [NSURL URLWithString:blog.homeURL];
    WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:targetURL];
    if (blog.isPrivate) {
        webViewController.authToken = blog.authToken;
        webViewController.username = blog.usernameForSite;
        webViewController.password = blog.password;
        webViewController.wpLoginURL = [NSURL URLWithString:blog.loginUrl];
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)showViewAdminForBlog:(Blog *)blog
{
    if (![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnection];
        return;
    }

    [WPAnalytics track:WPAnalyticsStatOpenedViewAdmin];

    NSString *dashboardUrl = [blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@"wp-admin/"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:dashboardUrl]];
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
        self.navigationItem.backBarButtonItem.title = self.blog.blogName;
        self.navigationItem.title = self.blog.blogName;
        [self.tableView reloadData];
    }
}

@end
