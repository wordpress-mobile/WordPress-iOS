#import "CommentsViewController.h"
#import "CommentViewController.h"
#import "Comment.h"
#import "Blog.h"
#import "WordPress-Swift.h"
#import "WPTableViewHandler.h"
#import <WordPressShared/WPStyleGuide.h>



static CGRect const CommentsActivityFooterFrame                 = {0.0, 0.0, 30.0, 30.0};
static CGFloat const CommentsActivityFooterHeight               = 50.0;
static NSInteger const CommentsRefreshRowPadding                = 4;
static NSInteger const CommentsFetchBatchSize                   = 10;

static NSString *RestorableBlogIdKey = @"restorableBlogIdKey";
static NSString *RestorableFilterIndexKey = @"restorableFilterIndexKey";

@interface CommentsViewController () <WPTableViewHandlerDelegate, WPContentSyncHelperDelegate, UIViewControllerRestoration, NoResultsViewControllerDelegate>
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
    controller.restorationClass = [controller class];
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
    [self configureTableViewFooter];
    [self configureTableViewHandler];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

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
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    
    // Register the cells
    NSString *nibName = [CommentsTableViewCell classNameWithoutNamespaces];
    UINib *nibInstance = [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:nibInstance forCellReuseIdentifier:CommentsTableViewCell.reuseIdentifier];
}

- (void)configureTableViewFooter
{
    // Hide the cellSeparators when the table is empty
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CommentsTableViewCell.estimatedRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CommentsTableViewCell *cell = (CommentsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CommentsTableViewCell.reuseIdentifier];
    
    if (!cell) {
        cell = [[CommentsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CommentsTableViewCell.reuseIdentifier];
    }

    [self configureCell:cell atIndexPath:indexPath];    
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
    [tableView deselectSelectedRowWithAnimation:YES];
    
    // Failsafe: Make sure that the Comment (still) exists
    NSArray *sections = self.tableViewHandler.resultsController.sections;
    if (indexPath.section >= sections.count) {
        return;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[indexPath.section];
    if (indexPath.row >= sectionInfo.numberOfObjects) {
        return;
    }
    
    // At last, push the details
    Comment *comment            = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    CommentViewController *vc   = [CommentViewController new];
    vc.comment                  = comment;

    [self.navigationController pushViewController:vc animated:YES];
    [CommentAnalytics trackCommentViewedWithComment:comment];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

#pragma mark - Comment Actions

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    __typeof(self) __weak weakSelf = self;
    NSMutableArray *actions = [NSMutableArray array];
    
    // Trash Action
    UIContextualAction *trash = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:NSLocalizedString(@"Trash", @"Trashes a comment") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [ReachabilityUtils onAvailableInternetConnectionDo:^{
            [weakSelf deleteComment:comment];
        }];
        completionHandler(YES);
    }];
    
    trash.backgroundColor = [UIColor murielError];
    [actions addObject:trash];
    
    if (comment.isApproved) {

        // Unapprove Action
        UIContextualAction *unapprove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Unapprove", @"Unapproves a Comment") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [ReachabilityUtils onAvailableInternetConnectionDo:^{
                [weakSelf unapproveComment:comment];
            }];
            completionHandler(YES);
        }];
        
        unapprove.backgroundColor = [UIColor murielNeutral30];
        [actions addObject:unapprove];
    } else {
        // Approve Action
        UIContextualAction *approve = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:NSLocalizedString(@"Approve", @"Approves a Comment") handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
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
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];

    [self.tableView setEditing:NO animated:YES];
    [service approveComment:comment success:nil failure:^(NSError *error) {
        DDLogError(@"Error approving comment: %@", error);
    }];
}

- (void)unapproveComment:(Comment *)comment
{
    [CommentAnalytics trackCommentUnApprovedWithComment:comment];
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    
    [self.tableView setEditing:NO animated:YES];
    [service unapproveComment:comment success:nil failure:^(NSError *error) {
        DDLogError(@"Error unapproving comment: %@", error);
    }];
}

- (void)deleteComment:(Comment *)comment
{
    [CommentAnalytics trackCommentTrashedWithComment:comment];
    CommentService *service = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    
    [self.tableView setEditing:NO animated:YES];
    [service deleteComment:comment success:nil failure:^(NSError *error) {
        DDLogError(@"Error deleting comment: %@", error);
    }];
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

- (void)configureCell:(nonnull CommentsTableViewCell *)cell atIndexPath:(nonnull NSIndexPath *)indexPath {
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
    return @"sectionIdentifier";
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
    __typeof(self) __weak weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    CommentService *commentService  = [[CommentService alloc] initWithManagedObjectContext:context];
    NSManagedObjectID *blogObjectID = self.blog.objectID;

    BOOL filterUnreplied = [self isUnrepliedFilterSelected:self.filterTabBar];

    [context performBlock:^{
        Blog *blogInContext = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
        if (!blogInContext) {
            return;
        }

        [commentService syncCommentsForBlog:blogInContext
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
    }];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    __typeof(self) __weak weakSelf = self;
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    CommentService *commentService  = [[CommentService alloc] initWithManagedObjectContext:context];
    NSManagedObjectID *blogObjectID = self.blog.objectID;
    
    [context performBlock:^{
        Blog *blogInContext = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
        if (!blogInContext) {
            return;
        }

        [commentService loadMoreCommentsForBlog:blogInContext
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
    [self.tableView addSubviewWithFadeAnimation:self.noResultsViewController.view];
    self.noResultsViewController.view.frame = self.tableView.frame;

    // Adjust the NRV placement to accommodate for the filterTabBar.
    CGRect noResultsFrame = self.noResultsViewController.view.frame;
    noResultsFrame.origin.y -= self.filterTabBar.frame.size.height;
    self.noResultsViewController.view.frame = noResultsFrame;
    
    [self.noResultsViewController didMoveToParentViewController:self];
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
                         accessoryView:nil];
    
    viewController.delegate = self;
}

- (NSString *)noResultsTitle
{
    return NSLocalizedString(@"No comments yet", @"Displayed when there are no comments in the Comments views.");
}

- (NSString *)retryButtonTitle
{
    return NSLocalizedString(@"Retry", comment: "A prompt to attempt the failed network request again.");
}

#pragma mark - NoResultsViewControllerDelegate

- (void)actionButtonPressed {
    // The action button is only shown on the No Connection view.
    [self refreshNoConnectionView];
}

#pragma mark - State Restoration

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSString *blogID = [coder decodeObjectForKey:RestorableBlogIdKey];
    if (!blogID) {
        return nil;
    }
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:blogID]];
    if (!objectID) {
        return nil;
    }
    
    NSError *error = nil;
    Blog *blog = (Blog *)[context existingObjectWithID:objectID error:&error];
    if (error || !blog) {
        return nil;
    }

    return [CommentsViewController controllerWithBlog:blog];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[[self.blog.objectID URIRepresentation] absoluteString] forKey:RestorableBlogIdKey];
    [coder encodeInteger:[self getSelectedIndex:self.filterTabBar] forKey:RestorableFilterIndexKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [self setSeletedIndex:[coder decodeIntegerForKey:RestorableFilterIndexKey] filterTabBar:self.filterTabBar];
    [super decodeRestorableStateWithCoder:coder];
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
