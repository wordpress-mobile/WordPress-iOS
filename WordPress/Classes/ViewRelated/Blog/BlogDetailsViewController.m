// Blog Details contents:
//
// + (No Title)
// | View Site
// | Stats
//
// + Publish
// | Blog Posts
// | Pages
// | Comments
//
// + Configuration
// | Edit Site
//
// + Admin
// | View Admin
//
// + Remove Site (only for self hosted)
// | Remove Site

#import "BlogDetailsViewController.h"
#import "EditSiteViewController.h"
#import "CommentsViewController.h"
#import "ThemeBrowserViewController.h"
#import "StatsViewController.h"
#import "WPWebViewController.h"
#import "WPTableViewCell.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "BlogService.h"
#import "WPTableViewSectionHeaderView.h"
#import "BlogDetailHeaderView.h"
#import "ReachabilityUtils.h"
#import "WPAccount.h"
#import "PostListViewController.h"
#import "PageListViewController.h"

const NSInteger BlogDetailsRowViewSite = 0;
const NSInteger BlogDetailsRowStats = 1;
const NSInteger BlogDetailsRowBlogPosts = 0;
const NSInteger BlogDetailsRowPages = 1;
const NSInteger BlogDetailsRowComments = 2;
const NSInteger BlogDetailsRowEditSite = 0;
const NSInteger BlogDetailsRowViewAdmin = 0;
const NSInteger BlogDetailsRowRemove = 0;

typedef NS_ENUM(NSInteger, TableSectionContentType) {
    TableViewSectionGeneralType = 0,
    TableViewSectionPublishType,
    TableViewSectionConfigurationType,
    TableViewSectionAdmin,
    TableViewSectionRemove,
    TableViewSectionCount
};

static NSString *const BlogDetailsCellIdentifier = @"BlogDetailsCell";
NSString * const WPBlogDetailsRestorationID = @"WPBlogDetailsID";
NSString * const WPBlogDetailsBlogKey = @"WPBlogDetailsBlogKey";
NSInteger const BlogDetailHeaderViewHorizontalMarginiPhone = 15;
NSInteger const BlogDetailHeaderViewVerticalMargin = 18;

NSInteger const BlogDetailsRowCountForSectionGeneralType = 2;
NSInteger const BlogDetailsRowCountForSectionPublishType = 3;
NSInteger const BlogDetailsRowCountForSectionConfigurationType = 1;
NSInteger const BlogDetailsRowCountForSectionAdmin = 1;
NSInteger const BlogDetailsRowCountForSectionRemove = 1;

@interface BlogDetailsViewController () <UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) BlogDetailHeaderView *headerView;
@property (nonatomic, weak) UIActionSheet *removeSiteActionSheet;
@property (nonatomic, weak) UIAlertView *removeSiteAlertView;

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

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:BlogDetailsCellIdentifier];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncBlog:_blog success:nil failure:nil];

    if (!self.blog.account.userID) {
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
                                                                 multiplier:1.f
                                                                   constant:headerWidth]];
        // Center the headerView inside the wrapper
        [headerWrapper addConstraint:[NSLayoutConstraint constraintWithItem:self.headerView
                                                                  attribute:NSLayoutAttributeCenterX
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:headerWrapper
                                                                  attribute:NSLayoutAttributeCenterX
                                                                 multiplier:1.f
                                                                   constant:0.f]];
        // Then, horizontally constrain the headerWrapper
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[headerWrapper]-|"
                                                                          options:0
                                                                          metrics:metrics
                                                                            views:views]];
        
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
    [self.tableView reloadData];
}

- (void)setBlog:(Blog *)blog
{
    _blog = blog;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (![self.blog supports:BlogFeatureRemovable]) {
        // No "Remove Site" for wp.com
        return TableViewSectionCount - 1;
    }
    return TableViewSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == TableViewSectionGeneralType) {
        return BlogDetailsRowCountForSectionGeneralType;
    } else if (section == TableViewSectionPublishType) {
        return BlogDetailsRowCountForSectionPublishType;
    } else if (section == TableViewSectionConfigurationType) {
        return BlogDetailsRowCountForSectionConfigurationType;
    } else if (section == TableViewSectionAdmin) {
        return BlogDetailsRowCountForSectionAdmin;
    } else if (section == TableViewSectionRemove) {
        return BlogDetailsRowCountForSectionRemove;
    }

    return 0;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == TableViewSectionGeneralType) {
        switch (indexPath.row) {
            case BlogDetailsRowViewSite:
                cell.textLabel.text = NSLocalizedString(@"View Site", nil);
                cell.imageView.image = [UIImage imageNamed:@"icon-menu-viewsite"];
                break;
            case BlogDetailsRowStats:
                cell.textLabel.text = NSLocalizedString(@"Stats", nil);
                cell.imageView.image = [UIImage imageNamed:@"icon-menu-stats"];
                break;
            default:
                break;
        }
    } else if (indexPath.section == TableViewSectionPublishType) {
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
    } else if (indexPath.section == TableViewSectionConfigurationType) {
        if (indexPath.row == BlogDetailsRowEditSite) {
            cell.textLabel.text = NSLocalizedString(@"Settings", nil);
            cell.imageView.image = [UIImage imageNamed:@"icon-menu-settings"];
        }
    } else if (indexPath.section == TableViewSectionAdmin) {
        if (indexPath.row == BlogDetailsRowViewAdmin) {
            cell.textLabel.text = NSLocalizedString(@"View Admin", nil);
            cell.imageView.image = [UIImage imageNamed:@"icon-menu-viewadmin"];
        }
    } else if (indexPath.section == TableViewSectionRemove) {
        if (indexPath.row == BlogDetailsRowRemove) {
            cell.textLabel.text = NSLocalizedString(@"Remove Site", @"Button to remove a site from the app");
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [WPStyleGuide errorRed];
            cell.imageView.image = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
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

    if (indexPath.section == TableViewSectionConfigurationType && indexPath.row == BlogDetailsRowEditSite) {
        EditSiteViewController *editSiteViewController = [[EditSiteViewController alloc] initWithBlog:self.blog];
        [self.navigationController pushViewController:editSiteViewController animated:YES];
    }

    Class controllerClass;
    if (indexPath.section == TableViewSectionGeneralType) {
        switch (indexPath.row) {
            case BlogDetailsRowViewSite:
                [self showViewSiteForBlog:self.blog];
                break;
            case BlogDetailsRowStats:
                [WPAnalytics track:WPAnalyticsStatStatsAccessed];
                controllerClass =  [StatsViewController class];
                break;
            default:
                break;
        }
    } else if (indexPath.section == TableViewSectionPublishType) {
        switch (indexPath.row) {
            case BlogDetailsRowBlogPosts:
                [self showPostList];
                return;
            case BlogDetailsRowPages:
                [self showPageList];
                return;
            case BlogDetailsRowComments:
                [WPAnalytics track:WPAnalyticsStatOpenedComments];
                controllerClass = [CommentsViewController class];
                break;
            default:
                break;
        }
    } else if (indexPath.section == TableViewSectionAdmin) {
        if (indexPath.row == BlogDetailsRowViewAdmin) {
            [self showViewAdminForBlog:self.blog];
        }
    } else if (indexPath.section == TableViewSectionRemove) {
        if (indexPath.row == BlogDetailsRowRemove) {
            [self showRemoveSiteForBlog:self.blog];
        }
    }

    // Check if the controller is already on the screen
    if ([self.navigationController.visibleViewController isMemberOfClass:controllerClass]) {
        if ([self.navigationController.visibleViewController respondsToSelector:@selector(setBlog:)]) {
            [self.navigationController.visibleViewController performSelector:@selector(setBlog:) withObject:self.blog];
        }
        [self.navigationController popToRootViewControllerAnimated:NO];

        return;
    }

    UIViewController *viewController = (UIViewController *)[[controllerClass alloc] init];
    viewController.restorationIdentifier = NSStringFromClass(controllerClass);
    viewController.restorationClass = controllerClass;
    if ([viewController respondsToSelector:@selector(setBlog:)]) {
        [viewController performSelector:@selector(setBlog:) withObject:self.blog];
        [self.navigationController pushViewController:viewController animated:YES];
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    if (title.length > 0) {
        WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
        header.title = title;
        return header;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *headingTitle = nil;
    if (section == TableViewSectionPublishType) {
        headingTitle = NSLocalizedString(@"Publish", @"");
    } else if (section == TableViewSectionConfigurationType) {
        headingTitle = NSLocalizedString(@"Configuration", @"");
    } else if (section == TableViewSectionAdmin) {
        headingTitle = NSLocalizedString(@"Admin", @"");
    }

    return headingTitle;
}

#pragma mark - Private methods

- (void)showPostList {
    [WPAnalytics track:WPAnalyticsStatOpenedPosts];
    UIViewController *controller = [PostListViewController controllerWithBlog:self.blog];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showPageList {
    [WPAnalytics track:WPAnalyticsStatOpenedPages];
    UIViewController *controller = [PageListViewController controllerWithBlog:self.blog];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showViewSiteForBlog:(Blog *)blog
{
    [WPAnalytics track:WPAnalyticsStatOpenedViewSite];

    NSURL *targetURL = [NSURL URLWithString:blog.homeURL];
    WPWebViewController *webViewController = [WPWebViewController webViewControllerWithURL:targetURL];
    if (blog.isPrivate) {
        webViewController.authToken = blog.authToken;
        webViewController.username = blog.username;
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

- (void)showRemoveSiteForBlog:(Blog *)blog
{
    NSString *model = [[UIDevice currentDevice] localizedModel];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to continue?\n All site data will be removed from your %@.", @"Title for the remove site confirmation alert, %@ will be replaced with iPhone/iPad/iPod Touch"), model];
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    NSString *destructiveTitle = NSLocalizedString(@"Remove Site", @"Button to remove a site from the app");
    if (IS_IPAD) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Remove Site", @"Remove site confirmation alert title")
                                                              message:title
                                                             delegate:self
                                                    cancelButtonTitle:cancelTitle
                                                    otherButtonTitles:destructiveTitle, nil];
        [alert show];
        self.removeSiteAlertView = alert;
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                 delegate:self
                                                        cancelButtonTitle:cancelTitle
                                                   destructiveButtonTitle:destructiveTitle
                                                        otherButtonTitles:nil];
        [actionSheet showInView:self.view];
        self.removeSiteActionSheet = actionSheet;
    }
}

- (void)confirmRemoveSite
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService removeBlog:self.blog];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Notification handlers

- (void)handleDataModelChange:(NSNotification *)note
{
    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    if ([deletedObjects containsObject:self.blog]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self confirmRemoveSite];
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        [self confirmRemoveSite];
    }
}

@end
