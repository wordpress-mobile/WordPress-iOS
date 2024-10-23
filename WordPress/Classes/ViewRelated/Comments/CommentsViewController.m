#import "CommentsViewController.h"
#import "Blog.h"
#import "WordPress-Swift.h"
#import "WPTableViewHandler.h"

@import WordPressShared;

@class Comment;

static CGRect const CommentsActivityFooterFrame                 = {0.0, 0.0, 30.0, 30.0};
static CGFloat const CommentsActivityFooterHeight               = 50.0;
static NSInteger const CommentsRefreshRowPadding                = 4;
static NSInteger const CommentsFetchBatchSize                   = 10;

static NSString *RestorableFilterIndexKey = @"restorableFilterIndexKey";

@interface CommentsViewController () <WPTableViewHandlerDelegate, WPContentSyncHelperDelegate, NoResultsViewControllerDelegate, CommentDetailsDelegate>
@property (nonatomic, strong) WPTableViewHandler        *tableViewHandler;
@property (nonatomic, strong) WPContentSyncHelper       *syncHelper;
@property (nonatomic, strong) NoResultsViewController   *noResultsViewController;
@property (nonatomic, strong) NoResultsViewController   *noConnectionViewController;
@property (nonatomic, strong) UIActivityIndicatorView   *footerActivityIndicator;
@property (nonatomic, strong) UIView                    *footerView;
@property (nonatomic, strong) Blog                      *blog;

@property (nonatomic) CommentStatusFilter currentStatusFilter;
@property (nonatomic) CommentStatusFilter cachedStatusFilter;
@property (weak, nonatomic) IBOutlet FilterTabBar *filterTabBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

// Keep track of the index path of the Comment displayed in comment details.
// Used to advance the displayed Comment when Next is selected on the moderation confirmation snackbar.
@property (nonatomic, strong) NSIndexPath *displayedCommentIndexPath;
@property (nonatomic, strong) CommentDetailViewController *commentDetailViewController;

@end

@implementation CommentsViewController

- (void)dealloc
{
    _syncHelper.delegate = nil;
    _tableViewHandler.delegate = nil;
}

+ (CommentsViewController *)controllerWithBlog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CommentsList" bundle:nil];
    CommentsViewController *controller = [storyboard instantiateInitialViewController];
    controller.blog = blog;
    return controller;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureFilterTabBar:self.filterTabBar];
    [self getSelectedFilterFromUserDefaults];
    [self configureNavBar];
    [self configureLoadMoreSpinner];
    [self initializeNoResultsViews];
    [self configureRefreshControl];
    [self configureSyncHelper];
    [self configureTableView];
    [self configureTableViewHeader];
    [self configureTableViewFooter];
    [self configureTableViewHandler];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshPullToRefresh];
    [self refreshNoResultsView];
    [self refreshAndSyncIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}


#pragma mark - Configuration

- (void)configureNavBar
{
    self.title = NSLocalizedString(@"Comments", @"Title for the Blog's Comments Section View");
}

- (void)configureLoadMoreSpinner
{
    // ContainerView
    CGFloat width                           = CGRectGetWidth(self.tableView.bounds);
    CGRect footerViewFrame                  = CGRectMake(0.0, 0.0, width, CommentsActivityFooterHeight);
    UIView *footerView                      = [[UIView alloc] initWithFrame:footerViewFrame];
    
    // Spinner
    UIActivityIndicatorView *indicator      = [[UIActivityIndicatorView alloc] initWithFrame:CommentsActivityFooterFrame];
    indicator.activityIndicatorViewStyle    = UIActivityIndicatorViewStyleMedium;
    indicator.hidesWhenStopped              = YES;
    indicator.autoresizingMask              = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    indicator.center                        = footerView.center;
    [indicator stopAnimating];

    [footerView addSubview:indicator];

    // Keep References
    self.footerActivityIndicator            = indicator;
    self.footerView                         = footerView;
}

- (void)configureRefreshControl
{
    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(refreshAndSyncWithInteraction) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
}

- (void)configureSyncHelper
{
    WPContentSyncHelper *syncHelper         = [WPContentSyncHelper new];
    syncHelper.delegate                     = self;
    self.syncHelper                         = syncHelper;
}

- (void)configureTableView
{
    self.tableView.accessibilityIdentifier  = @"Comments Table";

    // Register the cells
    UINib *listCellNibInstance = [UINib nibWithNibName:[ListTableViewCell classNameWithoutNamespaces] bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:listCellNibInstance forCellReuseIdentifier:ListTableViewCell.reuseIdentifier];

    UINib *listHeaderNibInstance = [UINib nibWithNibName:[ListTableHeaderView classNameWithoutNamespaces] bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:listHeaderNibInstance forHeaderFooterViewReuseIdentifier:ListTableHeaderView.reuseIdentifier];
}

- (void)configureTableViewHeader
{
    // Add an extra 10pt space on top of the first header view. Ref: https://git.io/JBQlU
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 10)];
    tableHeaderView.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView.tableHeaderView = tableHeaderView;
}

- (void)configureTableViewFooter
{
    // Hide the cellSeparators when the table is empty
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
}

- (void)configureTableViewHandler
{
    WPTableViewHandler *tableViewHandler    = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    tableViewHandler.delegate               = self;
    self.tableViewHandler                   = tableViewHandler;
}

#pragma mark - UITableViewDelegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewHandler tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return ListTableHeaderView.estimatedRowHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // fetch the section information
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.tableViewHandler.resultsController.sections objectAtIndex:section];
    if (!sectionInfo) {
        return nil;
    }

    ListTableHeaderView *headerView = (ListTableHeaderView *)[self.tableView dequeueReusableHeaderFooterViewWithIdentifier:ListTableHeaderView.reuseIdentifier];
    if (!headerView) {
        headerView = [[ListTableHeaderView alloc] initWithReuseIdentifier:ListTableHeaderView.reuseIdentifier];
    }

    headerView.title = [Comment descriptionForSectionIdentifier:sectionInfo.name];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ListTableViewCell.estimatedRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ListTableViewCell *cell = (ListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:ListTableViewCell.reuseIdentifier forIndexPath:indexPath];
    [self configureListCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Refresh only when we reach the last 3 rows in the last section
    NSInteger numberOfRowsInSection     = [self.tableViewHandler tableView:tableView numberOfRowsInSection:indexPath.section];
    NSInteger lastSection               = [self.tableViewHandler numberOfSectionsInTableView:tableView] - 1;
    
    if ((indexPath.section == lastSection) && (indexPath.row + CommentsRefreshRowPadding >= numberOfRowsInSection)) {
        if (self.syncHelper.hasMoreContent) {
            [self.syncHelper syncMoreContent];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isSidebarModeEnabled) {
        [tableView deselectSelectedRowWithAnimation:YES];
    }

    if (![self indexPathIsValid:indexPath]) {
        return;
    }

    self.displayedCommentIndexPath = indexPath;
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    self.commentDetailViewController = [[CommentDetailViewController alloc] initWithComment:comment
                                                                               isLastInList:[self isLastRow:indexPath]
                                                                       managedObjectContext:[ContextManager sharedInstance].mainContext];
    self.commentDetailViewController.commentDelegate = self;
    if (self.isSidebarModeEnabled) {
        self.commentDetailViewController.isSidebarModeEnabled = true;
        self.commentDetailViewController.navigationItem.hidesBackButton = YES;
        [self showDetailViewController:self.commentDetailViewController sender:nil];
    } else {
        [self.navigationController pushViewController:self.commentDetailViewController animated:YES];
    }
    [CommentAnalytics trackCommentViewedWithComment:comment];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

- (BOOL)indexPathIsValid:(NSIndexPath *)indexPath
{
    NSArray *sections = self.tableViewHandler.resultsController.sections;
    if (indexPath.section >= sections.count) {
        return NO;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[indexPath.section];
    if (indexPath.row >= sectionInfo.numberOfObjects) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isLastRow:(NSIndexPath *)indexPath
{
    NSInteger lastSectionIndex = [self.tableView numberOfSections] - 1;
    NSInteger lastRowIndex = [self.tableView numberOfRowsInSection:lastSectionIndex] - 1;
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
    return lastIndexPath == indexPath;
}

#pragma mark - Comment Actions

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    
    // If the current user cannot moderate comments, don't show the actions.
    if (!comment.canModerate) {
        return nil;
    }

    __typeof(self) __weak weakSelf = self;
    NSMutableArray *actions = [NSMutableArray array];
    
    // Trash Action
    UIContextualAction *trash = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:NSLocalizedString(@"Trash", @"Trashes a comment") handler:^(UIContextualAction * _Nonnull __unused action, __kindof UIView * _Nonnull __unused sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [ReachabilityUtils onAvailableInternetConnectionDo:^{
            [weakSelf deleteComment:comment];
        }];
        completionHandler(YES);
    }];
    
    trash.backgroundColor = [UIColor murielError];
    [actions addObject:trash];
    
    if (comment.isApproved) {

        // Unapprove Action
        UIContextualAction *unapprove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Unapprove", @"Unapproves a Comment") handler:^(UIContextualAction * _Nonnull __unused action, __kindof UIView * _Nonnull __unused sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [ReachabilityUtils onAvailableInternetConnectionDo:^{
                [weakSelf unapproveComment:comment];
            }];
            completionHandler(YES);
        }];
        
        unapprove.backgroundColor = [UIColor murielNeutral30];
        [actions addObject:unapprove];
    } else {
        // Approve Action
        UIContextualAction *approve = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Approve", @"Approves a Comment") handler:^(UIContextualAction * _Nonnull __unused action, __kindof UIView * _Nonnull __unused sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [ReachabilityUtils onAvailableInternetConnectionDo:^{
                [weakSelf approveComment:comment];
            }];
            completionHandler(YES);
        }];
        
        approve.backgroundColor = [UIColor murielPrimary];
        [actions addObject:approve];
    }
    
    UISwipeActionsConfiguration *swipeActions = [UISwipeActionsConfiguration configurationWithActions:actions];
    swipeActions.performsFirstActionWithFullSwipe = NO;
    return swipeActions;
}

- (void)approveComment:(Comment *)comment
{
    [CommentAnalytics trackCommentUnApprovedWithComment:comment];
    CommentService *service = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];;

    [self.tableView setEditing:NO animated:YES];
    [service approveComment:comment success:nil failure:^(NSError *error) {
        DDLogError(@"Error approving comment: %@", error);
    }];
}

- (void)unapproveComment:(Comment *)comment
{
    [CommentAnalytics trackCommentUnApprovedWithComment:comment];
    CommentService *service = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    
    [self.tableView setEditing:NO animated:YES];
    [service unapproveComment:comment success:nil failure:^(NSError *error) {
        DDLogError(@"Error unapproving comment: %@", error);
    }];
}

- (void)deleteComment:(Comment *)comment
{
    [CommentAnalytics trackCommentTrashedWithComment:comment];
    CommentService *service = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    
    [self.tableView setEditing:NO animated:YES];
    [service deleteComment:comment success:nil failure:^(NSError *error) {
        DDLogError(@"Error deleting comment: %@", error);
    }];
}

// When `Next` is tapped on the comment moderation confirmation snackbar,
// find the next comment in the list and update comment details with it.
- (void)showNextComment
{
    NSIndexPath *nextIndexPath;
    BOOL showingLastRowInSection = [self.tableViewHandler.resultsController isLastIndexPathInSection:self.displayedCommentIndexPath];

    if (showingLastRowInSection) {
        // Move to the first row in the next section.
        nextIndexPath = [NSIndexPath indexPathForRow:0
                                           inSection:self.displayedCommentIndexPath.section + 1];
    } else {
        // Move to the next row in the current section.
        nextIndexPath = [NSIndexPath indexPathForRow:self.displayedCommentIndexPath.row + 1
                                           inSection:self.displayedCommentIndexPath.section];
    }
    
    if (![self indexPathIsValid:nextIndexPath] || !self.commentDetailViewController) {
        return;
    }
    
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:nextIndexPath];
    [self.commentDetailViewController displayComment:comment isLastInList:[self isLastRow:nextIndexPath]];
    self.displayedCommentIndexPath = nextIndexPath;
}

#pragma mark - WPTableViewHandlerDelegate Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];

    // CommentService purges Comments that do not belong to the current filter.
    fetchRequest.predicate = [self predicateForFetchRequest:self.currentStatusFilter];

    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorDate];
    fetchRequest.fetchBatchSize = CommentsFetchBatchSize;
    
    return fetchRequest;
}

/// Configures a `ListTableViewCell` instance with a `Comment` object.
- (void)configureListCell:(nonnull ListTableViewCell *)cell atIndexPath:(nonnull NSIndexPath *)indexPath
{
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    [cell configureWithComment:comment];
}

- (NSString *)entityName
{
    return NSStringFromClass([Comment class]);
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    [self refreshNoResultsView];
}

- (void)deletingSelectedRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController popToViewController:self animated:YES];
}

- (NSString *)sectionNameKeyPath
{
    return @"relativeDateSectionIdentifier";
}

- (void)configureCell:(nonnull UITableViewCell *)cell atIndexPath:(nonnull NSIndexPath *)indexPath
{
    /// No implementation needed here; This method is added to remove protocol conformance warnings.
    ///
    /// Note that `WPTableViewHandler` will prioritize `tableView:cellForRowAtIndexPath:` when it is available.
    /// We're not using the `configureCell` method because the handler only dequeues cell with `DefaultCellIdentifier` for this method.
}

#pragma mark - Predicate Wrangling

- (void)updateFetchRequestPredicate:(CommentStatusFilter)statusFilter
{
    NSPredicate *predicate = [self predicateForFetchRequest:statusFilter];
    NSFetchedResultsController *resultsController = [[self tableViewHandler] resultsController];
    [[resultsController fetchRequest] setPredicate:predicate];
    NSError *error;
    [resultsController performFetch:&error];
    [self.tableView reloadData];
}

- (NSPredicate *)predicateForFetchRequest:(CommentStatusFilter)statusFilter
{
    NSPredicate *predicate;
    if (statusFilter == CommentStatusFilterAll && ![self isUnrepliedFilterSelected:self.filterTabBar]) {
        predicate = [NSPredicate predicateWithFormat:@"(blog == %@)", self.blog];
    } else {
        // Exclude any local replies from all filters except all.
        predicate = [NSPredicate predicateWithFormat:@"(blog == %@) AND commentID != nil", self.blog];
    }
    return predicate;
}

#pragma mark - WPContentSyncHelper Methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    [self refreshNoResultsView];
    
    __typeof(self) __weak weakSelf = self;

    BOOL filterUnreplied = [self isUnrepliedFilterSelected:self.filterTabBar];

    CommentService *commentService  = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    [commentService syncCommentsForBlog:self.blog
                             withStatus:self.currentStatusFilter
                        filterUnreplied:filterUnreplied
                                success:^(BOOL hasMore) {
        if (success) {
            weakSelf.cachedStatusFilter = weakSelf.currentStatusFilter;
            dispatch_async(dispatch_get_main_queue(), ^{
                success(hasMore);
            });
        }
    }
                                failure:^(NSError *error) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.footerActivityIndicator stopAnimating];
            [weakSelf refreshNoConnectionView];
        });
    }];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    __typeof(self) __weak weakSelf = self;

    CommentService *commentService  = [[CommentService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    [commentService loadMoreCommentsForBlog:self.blog
                                 withStatus:self.currentStatusFilter
                                    success:^(BOOL hasMore) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(hasMore);
            });
        }
    }
                                    failure:^(NSError *error) {
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.footerActivityIndicator stopAnimating];
        });
    }];
    
    [self refreshInfiniteScroll];
}

- (void)syncContentEnded:(WPContentSyncHelper *)syncHelper
{
    [self refreshInfiniteScroll];
    [self refreshNoResultsView];
    [self refreshPullToRefresh];
}

- (BOOL)contentIsEmpty
{
    return [self.tableViewHandler.resultsController isEmpty];
}


#pragma mark - View Refresh Helpers

- (void)refreshAndSyncWithInteraction
{
    if (!ReachabilityUtils.isInternetReachable) {
        [self refreshPullToRefresh];
        [self refreshNoConnectionView];
        return;
    }

    [self.syncHelper syncContentWithUserInteraction];
}

- (void)refreshAndSyncIfNeeded
{
    if (self.blog) {
        [self.syncHelper syncContent];
    }
}

- (void)refreshWithStatusFilter:(CommentStatusFilter)statusFilter
{
    [self updateFetchRequestPredicate:statusFilter];
    [self saveSelectedFilterToUserDefaults];
    self.currentStatusFilter = statusFilter;
    [self refreshAndSyncWithInteraction];
}

- (void)refreshInfiniteScroll
{
    NSParameterAssert(self.footerView);
    NSParameterAssert(self.footerActivityIndicator);
    
    if (self.syncHelper.isSyncing) {
        self.tableView.tableFooterView = self.footerView;
        [self.footerActivityIndicator startAnimating];
    } else if (!self.syncHelper.hasMoreContent) {
        [self configureTableViewFooter];
    }
}

- (void)refreshPullToRefresh
{
    if (self.tableView.refreshControl.isRefreshing) {
        [self.tableView.refreshControl endRefreshing];
    }
}

#pragma mark - No Results Views

- (void)initializeNoResultsViews
{
    self.noResultsViewController = [NoResultsViewController controller];
    self.noConnectionViewController = [NoResultsViewController controller];
}

- (void)refreshNoResultsView
{
    if (![self contentIsEmpty]) {
        [self.tableView setHidden:NO];
        [self.noResultsViewController removeFromView];
        return;
    }

    [self.noResultsViewController removeFromView];
    [self configureNoResults:self.noResultsViewController forNoConnection:NO];
    [self addChildViewController:self.noResultsViewController];
    [self adjustNoResultViewPlacement];
    [self.tableView addSubview:self.noResultsViewController.view];
    
    [self.noResultsViewController didMoveToParentViewController:self];
}

- (void)adjustNoResultViewPlacement
{
    // calling this too early results in wrong tableView frame used for initial state.
    // ensure that either the NRV or the table view is visible. Otherwise, skip the adjustment to prevent misplacements.
    if (!self.noResultsViewController.view.window && !self.tableView.window) {
        return;
    }

    // Adjust the NRV placement to accommodate for the filterTabBar.
    CGRect noResultsFrame = self.tableView.frame;
    noResultsFrame.origin.y = 0;
    self.noResultsViewController.view.frame = noResultsFrame;
}

- (void)refreshNoConnectionView
{
    if (ReachabilityUtils.isInternetReachable) {
        [self.tableView setHidden:NO];
        [self.noConnectionViewController removeFromView];
        [self refreshAndSyncIfNeeded];
        
        return;
    }
    
    // Show cached results instead of No Connection view.
    if (self.cachedStatusFilter == self.currentStatusFilter) {
        [self.tableView setHidden:NO];
        [self.noConnectionViewController removeFromView];
        
        return;
    }
    
    // No Connection is already being shown.
    if (self.noConnectionViewController.parentViewController) {
        return;
    }

    [self.noConnectionViewController removeFromView];
    [self configureNoResults:self.noConnectionViewController forNoConnection:YES];
    self.noConnectionViewController.delegate = self;

    // Because the table shows cached results from the last successful filter,
    // some comments can appear below the No Connection view.
    // So hide the table when showing No Connection.
    [self.tableView setHidden:YES];
    [self addChildViewController:self.noConnectionViewController];
    [self.view insertSubview:self.noConnectionViewController.view belowSubview:self.filterTabBar];
    self.noConnectionViewController.view.frame = self.tableView.frame;
    [self.noConnectionViewController didMoveToParentViewController:self];
}

- (void)configureNoResults:(NoResultsViewController *)viewController forNoConnection:(BOOL)forNoConnection {
    [viewController configureWithTitle:self.noResultsTitle
                       attributedTitle:nil
                     noConnectionTitle:nil
                           buttonTitle:forNoConnection ? self.retryButtonTitle : nil
                              subtitle:nil
                  noConnectionSubtitle:nil
                    attributedSubtitle:nil
       attributedSubtitleConfiguration:nil
                                 image:@"wp-illustration-empty-results"
                         subtitleImage:nil
                         accessoryView:[self loadingAccessoryView]];
    
    viewController.delegate = self;
}

- (NSString *)noResultsTitle
{
    if (self.syncHelper.isSyncing) {
        return NSLocalizedString(@"Fetching comments...",
                                 @"A brief prompt shown when the comment list is empty, letting the user know the app is currently fetching new comments.");
    }

    return NSLocalizedString(@"No comments yet", @"Displayed when there are no comments in the Comments views.");
}

- (NSString *)retryButtonTitle
{
    return NSLocalizedString(@"Retry", comment: "A prompt to attempt the failed network request again.");
}

- (UIView *)loadingAccessoryView
{
    if (self.syncHelper.isSyncing) {
        return [NoResultsViewController loadingAccessoryView];
    }

    return nil;
}

#pragma mark - NoResultsViewControllerDelegate

- (void)actionButtonPressed
{
    // The action button is only shown on the No Connection view.
    [self refreshNoConnectionView];
}

#pragma mark - CommentDetailsDelegate

- (void)nextCommentSelected
{
    [self showNextComment];
}

#pragma mark - User Defaults

- (void)saveSelectedFilterToUserDefaults
{
    [NSUserDefaults.standardUserDefaults setInteger:[self getSelectedIndex:self.filterTabBar] forKey:RestorableFilterIndexKey];
}

- (void)getSelectedFilterFromUserDefaults
{
    NSInteger filterIndex = [NSUserDefaults.standardUserDefaults integerForKey:RestorableFilterIndexKey] ?: 0;
    [self setSeletedIndex:filterIndex filterTabBar:self.filterTabBar];
}

@end
