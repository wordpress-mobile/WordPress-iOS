#import "CommentsViewController.h"
#import "CommentsTableViewCell.h"
#import "CommentViewController.h"
#import "CommentService.h"
#import "Comment.h"

#import "WordPress-Swift.h"
#import "WPTableViewHandler.h"
#import "WPGUIConstants.h"
#import "WPNoResultsView.h"
#import "UIView+Subviews.h"
#import "ContextManager.h"


CGFloat const CommentsStandardOffset        = 16.0;
CGFloat const CommentsSectionHeaderHeight   = 24.0;
CGRect const CommentsActivityFooterFrame    = {0.0f, 0.0f, 30.0f, 30.0f};
CGFloat const CommentsActivityFooterHeight  = 50.0f;


@interface CommentsViewController () <WPTableViewHandlerDelegate, WPContentSyncHelperDelegate>
@property (nonatomic, strong) WPTableViewHandler        *tableViewHandler;
@property (nonatomic, strong) WPContentSyncHelper       *syncHelper;
@property (nonatomic, strong) WPNoResultsView           *noResultsView;
@property (nonatomic, strong) UIActivityIndicatorView   *footerActivityIndicator;
@end


@implementation CommentsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.syncHelper.delegate = nil;
    self.tableViewHandler.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSParameterAssert(self.view);
    NSParameterAssert(self.tableView);
    
    [self configureNavBar];
    [self configureActivityFooter];
    [self configureSyncHelper];
    [self configureTableView];
    [self configureTableViewHandler];
    [self configureRefreshControl];
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Returning to the comments list while the reply-to keyboard is visible
    // messes with the bottom contentInset. Let's reset it just in case.
    UIEdgeInsets contentInset   = self.tableView.contentInset;
    contentInset.bottom         = 0;
    self.tableView.contentInset = contentInset;
}


#pragma mark - Configuration

- (void)configureActivityFooter
{
    UIActivityIndicatorView *indicator  = [[UIActivityIndicatorView alloc] initWithFrame:CommentsActivityFooterFrame];
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    indicator.hidesWhenStopped          = YES;
    indicator.autoresizingMask          = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [indicator stopAnimating];
    self.footerActivityIndicator        = indicator;
}

- (void)configureNavBar
{
    self.title = NSLocalizedString(@"Comments", @"");
}

- (void)configureRefreshControl
{
    UIRefreshControl *refreshControl        = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
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
    
    // iPad Fix: contentInset breaks tableSectionViews
    if (UIDevice.isPad) {
        self.tableView.tableHeaderView      = [[UIView alloc] initWithFrame:WPTableHeaderPadFrame];
        self.tableView.tableFooterView      = [[UIView alloc] initWithFrame:WPTableFooterPadFrame];
        
    // iPhone Fix: Hide the cellSeparators, when the table is empty
    } else {
        self.tableView.tableFooterView      = [UIView new];
    }
    
    // Register the cells!
    Class cellClass = [CommentsTableViewCell class];
    [self.tableView registerClass:cellClass forCellReuseIdentifier:NSStringFromClass(cellClass)];
}

- (void)configureTableViewHandler
{
    WPTableViewHandler *tableViewHandler    = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    tableViewHandler.cacheRowHeights        = YES;
    tableViewHandler.delegate               = self;
    self.tableViewHandler                   = tableViewHandler;
}

- (void)configureNoResultsView
{
    WPNoResultsView *noResultsView          = [WPNoResultsView new];
    noResultsView.titleText                 = NSLocalizedString(@"No comments yet", @"Displayed when the user pulls up the comments view and they have no comments");
    self.noResultsView                      = noResultsView;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Failsafe: Make sure that the Notification (still) exists
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
    [self showNoResultsViewIfNeeded];
}


#pragma mark - Actions

- (void)refresh
{
    [self.syncHelper syncContentWithUserInteraction];
}


#pragma mark - WPContentSyncHelper Methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    CommentService *commentService  = [[CommentService alloc] initWithManagedObjectContext:context];
    NSManagedObjectID *blogObjectID = self.blog.objectID;
    [context performBlock:^{
        Blog *blogInContext = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
        if (blogInContext) {
            [commentService syncCommentsForBlog:blogInContext success:^{
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success(true);
                    });
                }
            } failure:^(NSError *error) {
                if (failure) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failure(error);
                    });
                }
            }];
        }
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
                                                        success(hasMore);
                                                    }
                                        }
                                        failure:^(NSError *error) {
                                                    if (failure) {
                                                        failure(error);
                                                    }
                                        }];
    }];
}


#pragma mark - WPNoResultsView Methods

- (void)showNoResultsViewIfNeeded
{
    // Remove If Needed
    if (self.tableViewHandler.resultsController.fetchedObjects.count) {
        [self.noResultsView removeFromSuperview];
        return;
    }
    
    // Attach the view
    WPNoResultsView *noResultsView  = self.noResultsView;
    if (!noResultsView.superview) {
        [self.tableView addSubviewWithFadeAnimation:noResultsView];
    }
    
    // Refresh its properties: The user may have signed into WordPress.com
    noResultsView.titleText = NSLocalizedString(@"No comments yet", @"Displayed when the user pulls up the comments view and they have no comments");
}

- (WPNoResultsView *)noResultsView
{
    if (!_noResultsView) {
        _noResultsView = [WPNoResultsView new];
    }
    
    return _noResultsView;
}




//- (BOOL)isSyncing
//{
//    return [CommentService isSyncingCommentsForBlog:self.blog];
//}
//
//- (NSDate *)lastSyncDate
//{
//    return self.blog.lastCommentsSync;
//}

@end
