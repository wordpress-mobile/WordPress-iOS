#import "CommentsViewController.h"
#import "CommentsTableViewCell.h"
#import "CommentViewController.h"
#import "CommentService.h"
#import "Comment.h"
#import "Blog.h"

#import "WordPress-Swift.h"
#import "WPTableViewHandler.h"
#import "WPGUIConstants.h"
#import "WPNoResultsView.h"
#import "UIView+Subviews.h"
#import "ContextManager.h"


CGFloat const CommentsStandardOffset        = 16.0;
CGFloat const CommentsSectionHeaderHeight   = 24.0;
CGRect const CommentsActivityFooterFrame    = {0.0, 0.0, 30.0, 30.0};
CGFloat const CommentsActivityFooterHeight  = 50.0;


@interface CommentsViewController () <WPTableViewHandlerDelegate, WPContentSyncHelperDelegate>
@property (nonatomic, strong) WPTableViewHandler        *tableViewHandler;
@property (nonatomic, strong) WPContentSyncHelper       *syncHelper;
@property (nonatomic, strong) WPNoResultsView           *noResultsView;
@property (nonatomic, strong) UIActivityIndicatorView   *footerActivityIndicator;
@property (nonatomic, strong) UIView                    *footerView;
@end


@implementation CommentsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _syncHelper.delegate = nil;
    _tableViewHandler.delegate = nil;
}

- (void)viewDidLoad
{    
    [super viewDidLoad];
    
    [self configureNavBar];
    [self configureLoadMoreSpinner];
    [self configureNoResultsView];
    [self configureRefreshControl];
    [self configureSyncHelper];
    [self configureTableView];
    [self configureTableViewFooter];
    [self configureTableViewHandler];
    
    [self refreshAndSync];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Manually deselect the selected row. This is required due to a bug in iOS7 / iOS8
    [self.tableView deselectSelectedRowWithAnimation:YES];
    
    // Refresh the UI
    [self refreshNoResultsView];
}


#pragma mark - Configuration

- (void)configureNavBar
{
    self.title = NSLocalizedString(@"Comments", @"");
}

- (void)configureLoadMoreSpinner
{
    // ContainerView
    CGFloat width                           = CGRectGetWidth(self.tableView.bounds);
    CGRect footerViewFrame                  = CGRectMake(0.0, 0.0, width, CommentsActivityFooterHeight);
    UIView *footerView                      = [[UIView alloc] initWithFrame:footerViewFrame];
    
    // Spinner
    UIActivityIndicatorView *indicator      = [[UIActivityIndicatorView alloc] initWithFrame:CommentsActivityFooterFrame];
    indicator.activityIndicatorViewStyle    = UIActivityIndicatorViewStyleGray;
    indicator.hidesWhenStopped              = YES;
    indicator.autoresizingMask              = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    indicator.center                        = footerView.center;
    [indicator stopAnimating];

    [footerView addSubview:indicator];

    // Keep References!
    self.footerActivityIndicator            = indicator;
    self.footerView                         = footerView;
}

- (void)configureNoResultsView
{
    WPNoResultsView *noResultsView          = [WPNoResultsView new];
    noResultsView.titleText                 = NSLocalizedString(@"No comments yet", @"Displayed when the user pulls up the comments view and they have no comments");
    self.noResultsView                      = noResultsView;
    
    [self.view addSubview:noResultsView];
}

- (void)configureRefreshControl
{
    UIRefreshControl *refreshControl        = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(refreshAndSyncWithInteraction) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
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
    
    // Register the cells!
    Class cellClass = [CommentsTableViewCell class];
    [self.tableView registerClass:cellClass forCellReuseIdentifier:NSStringFromClass(cellClass)];
}

- (void)configureTableViewFooter
{
    // iPad Fix: contentInset breaks tableSectionViews
    if (UIDevice.isPad) {
        self.tableView.tableHeaderView      = [[UIView alloc] initWithFrame:WPTableHeaderPadFrame];
        self.tableView.tableFooterView      = [[UIView alloc] initWithFrame:WPTableFooterPadFrame];
        
    // iPhone Fix: Hide the cellSeparators, when the table is empty
    } else {
        self.tableView.tableFooterView      = [UIView new];
    }
}

- (void)configureTableViewHandler
{
    WPTableViewHandler *tableViewHandler    = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    tableViewHandler.cacheRowHeights        = YES;
    tableViewHandler.delegate               = self;
    self.tableViewHandler                   = tableViewHandler;
}


#pragma mark - UITableViewDelegate Methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    return [CommentsTableViewCell rowHeightForContentProvider:comment andWidth:WPTableViewFixedWidth];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = NSStringFromClass([CommentsTableViewCell class]);
    CommentsTableViewCell *cell = (CommentsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    NSAssert([cell isKindOfClass:[CommentsTableViewCell class]], nil);
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Refresh only when we reach the last 3 rows in the last section!
    NSInteger const refreshRowPadding   = 4;
    NSInteger numberOfRowsInSection     = [self.tableViewHandler tableView:tableView numberOfRowsInSection:indexPath.section];
    NSInteger lastSection               = [self.tableViewHandler numberOfSectionsInTableView:tableView] - 1;
    
    if ((indexPath.section == lastSection) && (indexPath.row + refreshRowPadding >= numberOfRowsInSection)) {
        if (self.syncHelper.hasMoreContent) {
            [self.syncHelper syncMoreContent];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Failsafe: Make sure that the Comment (still) exists
    NSArray *sections = self.tableViewHandler.resultsController.sections;
    if (indexPath.section >= sections.count) {
        [tableView deselectSelectedRowWithAnimation:YES];
        return;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = sections[indexPath.section];
    if (indexPath.row >= sectionInfo.numberOfObjects) {
        [tableView deselectSelectedRowWithAnimation:YES];
        return;
    }
    
    // At last, push the details
    Comment *comment            = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    CommentViewController *vc   = [CommentViewController new];
    vc.comment                  = comment;
        
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - WPTableViewHandlerDelegate Methods

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest            = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate                  = [NSPredicate predicateWithFormat:@"(blog == %@ AND status != %@)", self.blog, @"spam"];
    
    NSSortDescriptor *sortDescriptorStatus  = [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO];
    NSSortDescriptor *sortDescriptorDate    = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    fetchRequest.sortDescriptors            = @[sortDescriptorStatus, sortDescriptorDate];
    fetchRequest.fetchBatchSize             = 10;
    
    return fetchRequest;
}

- (void)configureCell:(CommentsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    cell.contentProvider = comment;
}

- (NSString *)sectionNameKeyPath
{
    return @"status";
}

- (NSString *)entityName
{
    return NSStringFromClass([Comment class]);
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    [self refreshNoResultsView];
}


#pragma mark - WPContentSyncHelper Methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    CommentService *commentService  = [[CommentService alloc] initWithManagedObjectContext:context];
    NSManagedObjectID *blogObjectID = self.blog.objectID;
    [context performBlock:^{
        Blog *blogInContext = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
        if (!blogInContext) {
            return;
        }
        
        [commentService syncCommentsForBlog:blogInContext
                                    success:^{
                                                if (success) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        success(true);
                                                    });
                                                }
                                    }
                                    failure:^(NSError *error) {
                                                if (failure) {
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        failure(error);
                                                    });
                                                }
                                    }];
    }];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    CommentService *commentService  = [[CommentService alloc] initWithManagedObjectContext:context];
    [context performBlock:^{
        Blog *blogInContext = (Blog *)[context existingObjectWithID:self.blog.objectID error:nil];
        if (!blogInContext) {
            return;
        }
        
        [commentService loadMoreCommentsForBlog:blogInContext
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
                                        }];
    }];
    
    [self refreshInfiniteScroll];
}

- (void)syncContentEnded
{
    [self refreshInfiniteScroll];
    [self refreshNoResultsView];
    [self refreshPullToRefresh];
}


#pragma mark - View Refresh Helpers

- (void)refreshAndSyncWithInteraction
{
    [self.syncHelper syncContentWithUserInteraction];
}

- (void)refreshAndSync
{
    [self.syncHelper syncContent];
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
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (void)refreshNoResultsView
{
    BOOL isTableViewEmpty = (self.tableViewHandler.resultsController.fetchedObjects.count == 0);
    BOOL shouldPerformAnimation = self.noResultsView.hidden;
    
    self.noResultsView.hidden = !isTableViewEmpty;
    
    if (!isTableViewEmpty) {
        return;
    }
    
    // Display NoResultsView
    [self.noResultsView centerInSuperview];
    
    if (shouldPerformAnimation) {
        [self.noResultsView fadeInWithAnimation];
    }
}

@end
