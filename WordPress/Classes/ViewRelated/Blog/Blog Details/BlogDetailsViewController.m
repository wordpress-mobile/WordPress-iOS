#import "BlogDetailsViewController.h"

#import "AccountService.h"
#import "BlogService.h"
#import "CommentsViewController.h"
#import "SiteSettingsViewController.h"
#import "SharingViewController.h"
#import "StatsViewController.h"
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"
#import "MenusViewController.h"

@import Gridicons;
@import Reachability;
@import WordPressData;
@import WordPressShared;

#pragma mark -

@interface BlogDetailsViewController () <UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *headerViewHorizontalConstraints;
@property (nonatomic, strong) BlogService *blogService;

@property (nonatomic) BOOL hasLoggedDomainCreditPromptShownEvent;

@property (nonatomic, strong) BlogDetailsTableViewModel *tableViewModel;

@end

@implementation BlogDetailsViewController

#pragma mark = Lifecycle Methods

- (instancetype)init
{
    self = [super init];

    if (self) {
        self.isScrollEnabled = false;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.isSidebarModeEnabled) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    } else if (self.isScrollEnabled) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    } else {
        _tableView = [[IntrinsicTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
        self.tableView.scrollEnabled = false;
    }

    self.tableViewModel = [[BlogDetailsTableViewModel alloc] initWithBlog:self.blog viewController:self];
    [self.tableViewModel configureWithTableView:self.tableView];

    self.tableView.translatesAutoresizingMaskIntoConstraints = false;
    if (self.isSidebarModeEnabled) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 8, 0, 0); // Left inset
    }
    [self.view addSubview:self.tableView];
    [self.view pinSubviewToAllEdges:self.tableView];

    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(pulledToRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;

    self.tableView.accessibilityIdentifier = @"Blog Details Table";

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [WPStyleGuide configureAutomaticHeightRowsFor:self.tableView];

    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;

    self.hasLoggedDomainCreditPromptShownEvent = NO;

    self.blogService = [[BlogService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    [self preloadMetadata];

    if (self.blog.account && !self.blog.account.userID) {
        // User's who upgrade may not have a userID recorded.
        AccountService *acctService = [[AccountService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
        [acctService updateUserDetailsForAccount:self.blog.account success:nil failure:nil];
    }

    [self observeManagedObjectContextObjectsDidChangeNotification];

    [self observeGravatarImageUpdate];

    [self registerForTraitChanges:@[[UITraitHorizontalSizeClass self]] withAction:@selector(handleTraitChanges)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self observeWillEnterForegroundNotification];

    [self.tableViewModel viewWillAppear];

    // Configure and reload table data when appearing to ensure pending comment count is updated
    [self configureTableViewData];

    [self reloadTableViewPreservingSelection];
    [self preloadBlogData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self createUserActivity];

    [WPAnalytics trackEvent: WPAnalyticsEventMySiteSiteMenuShown];

    if ([self shouldShowJetpackInstallCard]) {
        [WPAnalytics trackEvent:WPAnalyticsEventJetpackInstallFullPluginCardViewed
                     properties:@{WPAppAnalyticsKeyTabSource: @"site_menu"}];
    }

    if ([self shouldShowBlaze]) {
        [ObjCBridge trackBlazeEntryPointDisplayedWithSource:BlazeSourceMenuItem];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopObservingWillEnterForegroundNotification];
}

- (void)handleTraitChanges
{
    // Required to add / remove "Home" section when switching between regular and compact width
    [self configureTableViewData];

    // Required to update disclosure indicators depending on split view status
    [self reloadTableViewPreservingSelection];
}

#pragma mark - Data Model setup

- (void)reloadTableViewPreservingSelection
{
    [self.tableViewModel reloadTableViewPreservingSelection:self.tableView];
}

- (UITableViewScrollPosition)optimumScrollPositionForIndexPath:(NSIndexPath *)indexPath
{
    if (self.isSidebarModeEnabled) {
        return UITableViewScrollPositionNone;
    }
    // Try and avoid scrolling if not necessary
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
    BOOL cellIsNotFullyVisible = !CGRectContainsRect(self.tableView.bounds, cellRect);
    return (cellIsNotFullyVisible) ? UITableViewScrollPositionMiddle : UITableViewScrollPositionNone;
}

- (void)configureTableViewData
{
    [self.tableViewModel configureTableViewData];
}

- (Boolean)isSplitViewDisplayed {
    return self.isSidebarModeEnabled;
}

#pragma mark Site Switching

- (void)switchToBlog:(Blog*)blog
{
    self.blog = blog;
    [self showInitialDetailsForBlog];
    [self.tableView reloadData];
    [self preloadMetadata];
}

- (void)showInitialDetailsForBlog
{
    [self.tableViewModel showInitialDetailsForBlog];
}

#pragma mark - Private methods

- (void)preloadBlogData
{
    // only preload on wifi
    if ([ReachabilityUtils.internetReachability isReachableViaWiFi] == false) {
        return;
    }

    [self preloadComments];
    [self preloadMetadata];
    [self preloadDomains];
}

- (void)preloadComments
{
    CommentService *commentService = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];

    if ([CommentService shouldRefreshCacheFor:self.blog]) {
        [commentService syncCommentsForBlog:self.blog withStatus:CommentStatusFilterAll success:nil failure:nil];
    }
}

- (void)preloadMetadata
{
    __weak __typeof(self) weakSelf = self;
    [self.blogService syncBlogAndAllMetadata:self.blog
                           completionHandler:^{
                               [weakSelf configureTableViewData];
                               [weakSelf reloadTableViewPreservingSelection];
                           }];
}

- (void)preloadDomains
{
    if (![self shouldAddDomainRegistrationRow]) {
        return;
    }

    [self.blogService refreshDomainsFor:self.blog
                                success:nil
                                failure:nil];
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
    [alertController addDestructiveActionWithTitle:destructiveTitle handler:^(UIAlertAction * __unused action) {
        [self confirmRemoveSite];
    }];

    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Notification handlers

- (void)handleDataModelChange:(NSNotification *)note
{
    NSSet *deletedObjects = note.userInfo[NSDeletedObjectsKey];
    if ([deletedObjects containsObject:self.blog]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        return;
    }

    if (self.blog.account == nil || self.blog.account.isDeleted) {
        // No need to reload this screen if the blog's account is deleted (i.e. during logout)
        return;
    }

    NSSet *updatedObjects = note.userInfo[NSUpdatedObjectsKey];
    if ([updatedObjects containsObject:self.blog] || [updatedObjects containsObject:self.blog.settings]) {
        [self configureTableViewData];
        [self reloadTableViewPreservingSelection];
    }
}

- (void)handleWillEnterForegroundNotification:(NSNotification *)note
{
    [self configureTableViewData];
    [self reloadTableViewPreservingSelection];
}

- (void)observeManagedObjectContextObjectsDidChangeNotification
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDataModelChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:context];
}

- (void)observeWillEnterForegroundNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillEnterForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)stopObservingWillEnterForegroundNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
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

#pragma mark - UIAdaptivePresentationControllerDelegate

- (void)presentationControllerWillDismiss:(UIPresentationController *)presentationController {
    if (presentationController.presentedViewController == self.presentedSiteSettingsViewController) {
        [self.tableView deselectSelectedRowWithAnimation:YES];
    }
}

#pragma mark - Domain Registration

- (void)updateTableViewAndHeader
{
    [self updateTableView:^{}];
}

/// This method syncs the blog and its metadata, then reloads the table view.
///
- (void)updateTableView:(void(^)(void))completion
{
    __weak __typeof(self) weakSelf = self;
    [self.blogService syncBlogAndAllMetadata:self.blog
                           completionHandler:
     ^{
        [weakSelf configureTableViewData];
        [weakSelf reloadTableViewPreservingSelection];
        completion();
    }];
}

#pragma mark - Pull To Refresh

- (void)pulledToRefresh {
    [self pulledToRefreshWith:self.tableView.refreshControl onCompletion:^{}];
}

- (void)pulledToRefreshWith:(UIRefreshControl *)refreshControl onCompletion:( void(^)(void))completion {

    [self updateTableView: ^{
        // WORKAROUND: if we don't dispatch this asynchronously, the refresh end animation is clunky.
        // To recognize if we can remove this, simply remove the dispatch_async call and test pulling
        // down to refresh the site.
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [refreshControl endRefreshing];

            completion();
        });
    }];
}

@end
